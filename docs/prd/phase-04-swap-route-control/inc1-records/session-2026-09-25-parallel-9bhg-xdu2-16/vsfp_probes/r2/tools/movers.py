#!/usr/bin/env python3
"""movers.py ABFILE [CLASS...]: breakdown of an ab.py output by class x corpus, and
list rows of the named classes."""
import collections
import pathlib
import sys

rows = []
for l in open(sys.argv[1]):
    if l.startswith(("denominator", "summary")):
        continue
    p = l.rstrip("\n").split("\t")
    k, f = p[0], pathlib.Path(p[1]).name
    rows.append((k, f, p[3] if len(p) > 3 else "", p[4] if len(p) > 4 else ""))
c = collections.Counter((k, f[:2] if f[:2] in ("P_", "E_", "M_") else "lit") for k, f, *_ in rows)
for (k, corp), n in sorted(c.items()):
    print(f"{k:7s} {corp:4s} {n}")
want = set(sys.argv[2:])
for k, f, a, b in rows:
    if k in want:
        print(f"{k}\t{f}\tA:{a[-110:]}\tB:{b[-110:]}")
