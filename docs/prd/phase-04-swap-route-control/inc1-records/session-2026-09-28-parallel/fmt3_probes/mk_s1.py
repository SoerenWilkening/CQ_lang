#!/usr/bin/env python3
"""Stage-1 every C source in the given dirs (every CASE of matrix sources) against INC/CQ.h
into OUTDIR, and write OUTDIR/list.txt (non-empty modules only).
Usage: mk_s1.py INC OUTDIR SRCDIR [SRCDIR...] [-j N]"""
import os, re, subprocess, sys, glob
from concurrent.futures import ThreadPoolExecutor
L = "/usr/local/opt/llvm@19/bin"
args = sys.argv[1:]
J = 4
if "-j" in args:
    i = args.index("-j"); J = int(args[i + 1]); del args[i:i + 2]
INC, OUT, DIRS = args[0], args[1], args[2:]
os.makedirs(OUT, exist_ok=True)
jobs = []
for d in DIRS:
    for c in sorted(glob.glob(d + "/*.c")):
        if c.endswith(".lib.c"):
            continue
        src = open(c, errors="replace").read()
        cases = sorted(set(int(x) for x in re.findall(r"#define\s+CASE_\w+\s+(\d+)\b", src)))
        # UNIQUE per source dir: several probe dirs are all named `src/`, and the first
        # version of this line (dirname only) let them OVERWRITE each other (measured:
        # duplicate names in the first probe-dir sweep; that sweep is discarded).
        d0 = os.path.dirname(os.path.abspath(c))
        pre = "_".join(d0.split("/")[-3:]) + "__"
        if cases and "#ifndef CASE" in src:
            for k in cases:
                jobs.append((c, ["-DCASE=%d" % k], pre + os.path.basename(c)[:-2] + "__CASE%d" % k))
        else:
            jobs.append((c, [], pre + os.path.basename(c)[:-2]))
def one(j):
    c, d, tag = j
    o = os.path.join(OUT, tag + ".s1.ll")
    p = subprocess.run([L + "/clang", "-I" + INC, "-include", "CQ.h", "-O1", "-emit-llvm", "-S"] + d + [c, "-o", o],
                       capture_output=True)
    return o if p.returncode == 0 and os.path.exists(o) and os.path.getsize(o) > 0 else None
with ThreadPoolExecutor(J) as ex:
    res = list(ex.map(one, jobs))
okl = [r for r in res if r]
open(os.path.join(OUT, "list.txt"), "w").write("\n".join(okl) + "\n")
print(f"{len(jobs)} jobs, {len(okl)} stage-1 modules written to {OUT}, {len(jobs) - len(okl)} failed at stage 1")
