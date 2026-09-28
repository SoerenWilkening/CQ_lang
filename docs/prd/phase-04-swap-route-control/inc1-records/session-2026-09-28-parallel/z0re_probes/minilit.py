#!/usr/bin/env python3
"""A minimal lit runner for the mutation matrix: runs each fixture's `; RUN:` lines
with `%cq-opt` bound to a GIVEN binary (so a mutant can be measured without
relinking build/ir-pass/cq-opt under anything). It runs EXACTLY the RUN lines, flags
included (`--implicit-check-not` etc. — CLAUDE.md L10: a harness that runs a weaker
command than lit measures itself), through bash with `set -o pipefail` as lit's
internal shell does.

  minilit.py <cq-opt> <fixture.ll>...     → PASS/FAIL per fixture, then a count

A fixture using `%debugalloc-cq-opt` is reported SKIP (the mutants are cq-opt only).
"""
import os
import re
import subprocess
import sys
import tempfile

W = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a284a60d747f2ed82"
LLVM = "/usr/local/opt/llvm@19/bin"
OPT = sys.argv[1]
files = [os.path.abspath(x) for x in sys.argv[2:]]
if not files:
    sys.exit("minilit: no fixtures given (a 0-fixture run proves nothing)")


def run_lines(path):
    lines, cur = [], ""
    for raw in open(path, errors="replace"):
        m = re.match(r"\s*;\s*RUN:\s?(.*)$", raw)
        if not m:
            continue
        part = m.group(1).rstrip()
        if part.endswith("\\"):
            cur += part[:-1] + " "
            continue
        lines.append(cur + part)
        cur = ""
    return lines


n = {"PASS": 0, "FAIL": 0, "SKIP": 0}
for f in files:
    rl = run_lines(f)
    if not rl:
        print(f"SKIP(no RUN)\t{os.path.basename(f)}")
        n["SKIP"] += 1
        continue
    if any("%debugalloc-cq-opt" in l for l in rl):
        print(f"SKIP(debugalloc)\t{os.path.basename(f)}")
        n["SKIP"] += 1
        continue
    tmpd = tempfile.mkdtemp(prefix="minilit_")
    t = os.path.join(tmpd, "t")
    ok = True
    for l in rl:
        cmd = (l.replace("%cq-opt", OPT).replace("%cq-pass", "x")
                .replace("%filecheck", LLVM + "/FileCheck").replace("%s", f)
                .replace("%t", t))
        env = dict(os.environ, PATH=LLVM + os.pathsep + os.environ.get("PATH", ""))
        r = subprocess.run(["bash", "-c", "set -o pipefail; " + cmd], capture_output=True,
                           env=env, cwd=tmpd, timeout=600)
        if r.returncode != 0:
            ok = False
            break
    v = "PASS" if ok else "FAIL"
    n[v] += 1
    print(f"{v}\t{os.path.basename(f)}")
print(f"minilit: {len(files)} fixtures  PASS {n['PASS']}  FAIL {n['FAIL']}  SKIP {n['SKIP']}  bin={OPT}")
