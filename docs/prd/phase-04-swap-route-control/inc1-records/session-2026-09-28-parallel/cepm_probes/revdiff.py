#!/usr/bin/env python3
"""revdiff.py DIR — compare the reviewers' battery outputs written by revbat.sh:
<who>_subj2.txt (round 1b) vs <who>_subj3.txt (round 2). Prints the denominator, every
verdict change, and the after-tally. r1A lines: `name  TAG  VERDICT ...`;
r1B lines: `name | TAG VERDICT | C: ... | T: ...`."""
import sys
from collections import Counter

D = sys.argv[1]


def load(path, who):
    out = {}
    for line in open(path):
        line = line.rstrip("\n")
        if not line or line.startswith("denominator") or line.endswith("MISSING"):
            continue
        if who == "r1B":
            parts = [p.strip() for p in line.split(" | ")]
            toks = parts[1].split()
            out[parts[0]] = toks[1]
        else:
            toks = line.split()
            out[toks[0]] = toks[2]
    return out


for who in ("r1A", "r1B"):
    a = load(f"{D}/{who}_subj2.txt", who)
    b = load(f"{D}/{who}_subj3.txt", who)
    print(f"== {who}: {len(a)} pairs (round 1b), {len(b)} pairs (round 2)")
    for k in sorted(set(a) | set(b)):
        if a.get(k) != b.get(k):
            print(f"   CHANGED {k}: {a.get(k)} -> {b.get(k)}")
    print("   round 2 tally:", dict(sorted(Counter(b.values()).items())))
