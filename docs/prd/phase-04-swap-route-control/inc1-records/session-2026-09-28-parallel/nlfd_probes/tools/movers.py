#!/usr/bin/env python3
"""movers.py FIRST.txt FINAL.txt — summarise an ab.py mover list (kind x set counts) and
diff it against an earlier run's mover list (tags new / gone)."""
import sys
from collections import Counter


def rows(p):
    return [l.rstrip("\n") for l in open(p) if l.count("\t") >= 3]


old = {l.split("\t")[2] for l in rows(sys.argv[1])}
new = rows(sys.argv[2])
print(sorted(Counter((l.split("\t")[0], l.split("\t")[1]) for l in new).items()))
for l in new:
    if l.split("\t")[2] not in old:
        print("NEW vs first run:", l[:260])
for t in sorted(old - {l.split("\t")[2] for l in new}):
    print("GONE vs first run:", t)
