#!/usr/bin/env python3
"""Corpus A/B: OPT_A vs OPT_B over every ir-pass/test/*.ll. Compares exit code,
stdout sha256 and the first error line. Prints the denominator FIRST, then movers.
Usage: ab.py OPT_A OPT_B"""
import hashlib, os, subprocess, sys, glob
from concurrent.futures import ThreadPoolExecutor
W = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-aeb4c8cbea3df61df"
A, B = sys.argv[1], sys.argv[2]
def run(opt, f):
    p = subprocess.run([opt, "-passes=cq-lowering", "-S", f], capture_output=True, timeout=300)
    err = [l for l in p.stderr.decode(errors="replace").splitlines() if "error:" in l]
    return (p.returncode, hashlib.sha256(p.stdout).hexdigest()[:16],
            err[0].split("error:", 1)[1].strip() if err else "")
files = sorted(glob.glob(W + "/ir-pass/test/*.ll"))
print(f"denominator: {len(files)} fixtures  A={A}  B={B}", flush=True)
def one(f):
    return f, run(A, f), run(B, f)
with ThreadPoolExecutor(8) as ex:
    res = list(ex.map(one, files))
mov = [(f, a, b) for f, a, b in res if a != b]
nA = sum(1 for _, a, _ in res if a[0] == 0); nB = sum(1 for _, _, b in res if b[0] == 0)
print(f"accepts A={nA} B={nB}; movers {len(mov)} of {len(res)}")
for f, a, b in mov:
    kind = ("D->A" if a[0] != 0 and b[0] == 0 else "A->D" if a[0] == 0 and b[0] != 0
            else "STRING" if a[0] != 0 else "STREAM")
    print(f"{kind}\t{os.path.basename(f)}\tA={a}\tB={b}")
