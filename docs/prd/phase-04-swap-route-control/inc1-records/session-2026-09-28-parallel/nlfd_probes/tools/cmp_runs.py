#!/usr/bin/env python3
"""cmp_runs.py A.txt B.txt — join two pairs.py outputs on the subject name; print
verdict_A -> verdict_B per row (the B side's subject summary), movers flagged '*'."""
import sys


def load(p):
    d = {}
    for line in open(p):
        f = line.split()
        if len(f) >= 4 and f[2] == "vs":
            s = line.split("| S:")[1].split("| T:")[0].strip() if "| S:" in line else ""
            d[f[1] + " vs " + f[3]] = (f[0], s)
    return d


a, b = load(sys.argv[1]), load(sys.argv[2])
for k in a:
    if k not in b:
        print("MISSING", k)
        continue
    m = "*" if a[k][0] != b[k][0] else " "
    print(f"{m} {k:<26} {a[k][0]:<12} -> {b[k][0]:<12}  {b[k][1][:120]}")
