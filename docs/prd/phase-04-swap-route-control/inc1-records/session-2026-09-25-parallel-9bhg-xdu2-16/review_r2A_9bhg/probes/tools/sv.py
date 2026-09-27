#!/usr/bin/env python3
# sv.py <bin,bin> name... : verdict + warnings + 2b census + trace (args 5 7)
import sys; sys.path.insert(0, '.')
from h import *
bins = sys.argv[1].split(','); args = ["5", "7"]
for b in sys.argv[2:]:
    s1, e = build(b)
    if not s1: print(b, e); continue
    for bn in bins:
        rc, msg, s2, stderr = opt(bn, b)
        warns = sorted(set(l.split("): ")[-1] for l in stderr.splitlines() if l.startswith("warning")))
        print(f"== [{bn}] {b}: exit={rc} {msg} WARN={warns}")
        if s2:
            c, l = check2b(s2); print("   2b:", c, l[-1][l[-1].find('rail mint'):] if l else "")
            x, tr = linkrun(s2, args, f"{b}.{bn}")
            print("   " + " ; ".join(t for t in tr.splitlines() if t.strip()))
