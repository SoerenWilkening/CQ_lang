#!/usr/bin/env python3
"""Review r1 (scrubguard): does the BUILD compile each mutated header? For each probe:
copy ir-pass/include to <scratch>/mut/<id>/, overwrite the mutated files, then run the
build's OWN commands (from compile_commands.json) with -fsyntax-only and -I<mutdir> FIRST on
  (a) ir-pass/tools/scrub_selftest.cpp  (cq-opt/cq-scrub-selftest configuration)
  (b) ir-pass/src/CQLoweringPass.cpp    (CQPass configuration)
  (c) the probe's own usage TU (CQPass configuration), which USES the raw table.
usage: build_compiles.py <subject-root> <scratch> [id ...]"""
import json, os, shlex, shutil, subprocess, sys
from concurrent.futures import ThreadPoolExecutor
sys.dont_write_bytecode = True
ROOT, SCR = sys.argv[1], sys.argv[2]
sys.path.insert(0, os.path.join(ROOT, "tools")); sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import taintset_scrub_guard as G, rv_mutations
db = json.load(open(os.path.join(ROOT, "build", "compile_commands.json")))
def cmd_for(suffix):
    e = next(x for x in db if x["file"].endswith(suffix))
    argv = shlex.split(e["command"]); out = []; skip = False
    for a in argv:
        if skip: skip = False; continue
        if a in ("-o", "-c"): skip = (a == "-o"); continue
        if a.endswith(suffix): continue
        out.append(a)
    return out, e["directory"]
SEL = cmd_for("tools/scrub_selftest.cpp"); PASS = cmd_for("src/CQLoweringPass.cpp")
want = set(sys.argv[3:])
P = [p for p in rv_mutations.build(ROOT, G.EXTRA_INCLUDES) if p[2] == "attack" and (not want or p[0] in want)]
inc = os.path.join(ROOT, "ir-pass", "include")
def one(p):
    pid, label, kind, h, extra, use = p
    d = os.path.join(SCR, "mut", pid); shutil.rmtree(d, ignore_errors=True); os.makedirs(d)
    for f in os.listdir(inc):
        if f.endswith(".h"): shutil.copyfile(os.path.join(inc, f), os.path.join(d, f))
    open(os.path.join(d, "TaintPropagation.h"), "w").write(h)
    for f, t in (extra or {}).items(): open(os.path.join(d, f), "w").write(t)
    res = []
    jobs = [("scrub_selftest.cpp[cq-opt cfg]", SEL, os.path.join(ROOT, "ir-pass/tools/scrub_selftest.cpp")),
            ("CQLoweringPass.cpp[CQPass cfg]", PASS, os.path.join(ROOT, "ir-pass/src/CQLoweringPass.cpp"))]
    if use:
        u = os.path.join(d, "use.cpp"); open(u, "w").write(use)
        jobs.append(("usage TU[CQPass cfg]", PASS, u))
    for nm, (argv, cwd), src in jobs:
        r = subprocess.run([argv[0], f"-I{d}"] + argv[1:] + ["-fsyntax-only", "-w", src], cwd=cwd,
                           capture_output=True, text=True)
        errs = [l for l in r.stderr.splitlines() if " error: " in l][:2]
        res.append(f"    {nm}: exit {r.returncode}" + ("" if not errs else "  " + " | ".join(errs)[:300]))
    return pid, label, res
with ThreadPoolExecutor(2) as ex:
    for pid, label, res in ex.map(one, P):
        print(f"{pid:4s} {label}"); [print(x) for x in res]; sys.stdout.flush()
