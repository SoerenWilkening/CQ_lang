#!/usr/bin/env python3
"""Corpus A/B: SUBJECT cq-opt.m12 (the vsfp merge) vs REF cq-opt.main_c113 over
  lit     every ir-pass/test/*.ll
  e2e     every tests/e2e/*.c compiled standalone (p9/single.lst, rebuilt)
  multi   every run_slice_multi.sh registration (p9/multi.lst, rebuilt)
  probes  every probe module of every record dir (merge12/corp_list.txt)
  alias   r1B_9bhg's regenerated alias families (alias9/*/*.s1.ll)
NULL CONTROLS FIRST: the SUBJECT twice and the REF twice over the whole list; any
difference is printed and the script exits 2 before reporting movers.
Movers are classified A->D / D->A / DIAG / STREAM / STDERR and, where the module
has a hand-inlined twin (merge12/twins.tsv, or <x>T beside an alias module), the
subject's verdict is compared with the twin's on the SUBJECT: both decline ->
DECL-SAME/DECL-DIFF (stderr byte-equal); both accept -> TRACE-IDENT /
DEAD-REG-ONLY / TRACE-DIFF (link, run args "5 7" and "2 9")."""
import difflib
import hashlib
import pathlib
import re
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor

S = pathlib.Path("/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/"
                 "d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad")
W = pathlib.Path("/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a50057998e957b90e")
H = S / "merge12"
OUT = H / "ab"
OUT.mkdir(exist_ok=True)
L = pathlib.Path("/usr/local/opt/llvm@19/bin")
TPL, RT = W / "build/runtime/libcq_templates.a", W / "build/runtime/libcq_runtime.a"
SUB, REF = S / "frozen/cq-opt.m12", S / "frozen/cq-opt.main_c113"

sets = {
    "lit": sorted(str(p) for p in (W / "ir-pass/test").glob("*.ll")),
    "e2e": [l.strip() for l in open(S / "p9/single.lst") if l.strip()],
    "multi": [l.strip() for l in open(S / "p9/multi.lst") if l.strip()],
    "probes": [l.strip() for l in open(H / "corp_list.txt") if l.strip()],
    "alias": sorted(str(p) for p in (S / "alias9").glob("alias_gen*/*.s1.ll")
                    if not p.name.endswith("T.s1.ll")),
}
twins = dict(l.rstrip("\n").split("\t") for l in open(H / "twins.tsv") if l.strip())


def key(f):
    p = pathlib.Path(f)
    return p.parent.name + "/" + p.name


def run(b, f):
    r = subprocess.run([str(b), "-passes=cq-lowering", "-S", f, "-o", "-"], capture_output=True)
    err = next((l.split("error:", 1)[1].strip() for l in r.stderr.decode(errors="replace").splitlines()
                if "error:" in l), "")
    return (r.returncode, hashlib.sha256(r.stdout).hexdigest()[:16],
            hashlib.sha256(r.stderr).hexdigest()[:16], err)


def sweep(b, files):
    with ThreadPoolExecutor(8) as ex:
        return dict(zip(files, ex.map(lambda f: run(b, f), files)))


def cls(r, n):
    if r == n:
        return None
    if r[0] == 0 and n[0] != 0:
        return "A->D"
    if r[0] != 0 and n[0] == 0:
        return "D->A"
    if r[0] == 0 and n[0] == 0:
        return "STREAM" if r[1] != n[1] else "STDERR"
    return "DIAG" if r[3] != n[3] else "OTHER"


def traces(f, tag):
    s2 = OUT / f"{tag}.s2.ll"
    r = subprocess.run([str(SUB), "-passes=cq-lowering", "-S", f, "-o", str(s2)],
                       capture_output=True, text=True)
    if r.returncode:
        return r.returncode, r.stderr, None
    exe = OUT / f"{tag}.exe"
    lk = subprocess.run([str(L / "clang"), "-Wno-everything", str(s2), str(TPL), str(RT), "-o",
                         str(exe)], capture_output=True, text=True)
    if lk.returncode:
        return 0, "", ["LINKFAIL"]
    tr = []
    for args in (["5", "7"], ["2", "9"]):
        t = subprocess.run([str(exe)] + args, capture_output=True, text=True, timeout=60)
        tr.append(t.stdout.splitlines() + [f"exit={t.returncode}"])
    return 0, "", tr


def twin_verdict(f, tf):
    a, b = traces(f, "C_" + pathlib.Path(f).name), traces(tf, "T_" + pathlib.Path(tf).name)
    if a[0] and b[0]:
        return "DECL-SAME" if a[1] == b[1] else "DECL-DIFF"
    if a[0] or b[0]:
        return f"VERDICT-DIFF(C rc={a[0]}, T rc={b[0]})"
    if a[2] == b[2]:
        return "TRACE-IDENT"
    for x, y in zip(a[2], b[2]):
        d = [l for l in difflib.unified_diff(x, y, lineterm="", n=0)
             if not l.startswith(("---", "+++", "@@"))]
        if not d:
            continue
        plus = [l[1:] for l in d if l.startswith("+")]
        if any(l.startswith("-") for l in d) or len(plus) % 2:
            return "TRACE-DIFF"
        for i in range(0, len(plus), 2):
            m = re.fullmatch(r"cqrt_ry_\w+\((h\d+), -0x[0-9a-fp.+-]+\)", plus[i])
            if not (m and plus[i + 1] == f"cqrt_free({m.group(1)})"):
                return "TRACE-DIFF"
    return "DEAD-REG-ONLY"


def twin_of(f):
    p = pathlib.Path(f)
    tag = p.name[: -len(".s1.ll")]
    if tag.endswith("Q"):
        return None  # a quantum-verdict variant: <b>T is the CLASSICAL variant's twin
    if tag in twins:
        return str(p.with_name(twins[tag] + ".s1.ll"))
    t = p.with_name(tag + "T.s1.ll")
    return str(t) if t.exists() else None


allfiles = [f for fs in sets.values() for f in fs]
print("denominators: " + ", ".join(f"{k} {len(v)}" for k, v in sets.items()) + f"; total {len(allfiles)}")
s1, s2 = sweep(SUB, allfiles), sweep(SUB, allfiles)
r1, r2 = sweep(REF, allfiles), sweep(REF, allfiles)
ns = [f for f in allfiles if s1[f] != s2[f]]
nr = [f for f in allfiles if r1[f] != r2[f]]
print(f"null control SUBJECT twice: {len(ns)} of {len(allfiles)} differ {[key(f) for f in ns][:10]}")
print(f"null control REF twice:     {len(nr)} of {len(allfiles)} differ {[key(f) for f in nr][:10]}")
if ns or nr:
    print("NULL CONTROL FAILED — not reporting")
    sys.exit(2)
for name, fs in sets.items():
    mv = [(f, cls(r1[f], s1[f])) for f in fs if cls(r1[f], s1[f])]
    counts = {}
    for _, k in mv:
        counts[k] = counts.get(k, 0) + 1
    print(f"\n## {name}: {len(mv)} movers of {len(fs)} {counts}")
    for f, k in mv:
        tf = twin_of(f)
        tv = twin_verdict(f, tf) if tf else "no-twin"
        print(f"  {k:6} {key(f)}  [{tv}]  ref=[{r1[f][3][:80]}]  sub=[{s1[f][3][:80]}]")
