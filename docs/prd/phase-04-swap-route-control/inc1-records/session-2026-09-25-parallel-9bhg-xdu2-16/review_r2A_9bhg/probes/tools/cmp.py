#!/usr/bin/env python3
# cmp.py a.tsv b.tsv : classify movers (A->D, D->A, DIAG, STREAM, CRASH)
import sys
def load(p):
    return {l.split("\t")[0]: l.rstrip("\n").split("\t") for l in open(p)}
A, B = load(sys.argv[1]), load(sys.argv[2])
assert A.keys() == B.keys(), (len(A), len(B))
mv = {"A->D": [], "D->A": [], "DIAG": [], "STREAM": [], "CRASH": [], "OTHER": []}
for k in sorted(A):
    a, b = A[k], B[k]
    ra, rb = int(a[1]), int(b[1])
    if ra not in (0, 1) or rb not in (0, 1):
        if a[1:] != b[1:] or ra not in (0,1): mv["CRASH"].append((k, ra, rb, a[4], b[4]))
        continue
    if ra == 0 and rb == 1: mv["A->D"].append((k, b[4]))
    elif ra == 1 and rb == 0: mv["D->A"].append((k, a[4]))
    elif ra == 1 and rb == 1:
        if a[4] != b[4]: mv["DIAG"].append((k, a[4], b[4]))
    elif a[2] != b[2]: mv["STREAM"].append((k,))
print(f"denominator {len(A)}: " + ", ".join(f"{k}={len(v)}" for k, v in mv.items()))
if len(sys.argv) > 3:
    for k, v in mv.items():
        for x in v: print(k, *x, sep=" | ")
