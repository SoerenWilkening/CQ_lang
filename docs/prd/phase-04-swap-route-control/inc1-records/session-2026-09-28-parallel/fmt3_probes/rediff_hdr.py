#!/usr/bin/env python3
"""Re-diff the persisted stage-1 pairs of an ab_hdr.py run with the FIXED normaliser (blank lines
dropped). ab_hdr.REAL.txt's 598 S1MOVE lines were the unfixed normaliser's artefact: after the
attribute-group lines are deleted, the nomerge header leaves one extra BLANK line.
Usage: rediff_hdr.py TMPDIR"""
import re, glob, os, sys
T = sys.argv[1].rstrip("/") + "/"
NORM = [(re.compile(r"^attributes #\d+ = .*$", re.M), ""),
        (re.compile(r" #\d+"), ""),
        (re.compile(r"\bnomerge\b ?"), ""),
        (re.compile(r"^; ModuleID = .*$", re.M), ""),
        (re.compile(r'^source_filename = .*$', re.M), "")]
def norm(s):
    for rx, rep in NORM:
        s = rx.sub(rep, s)
    return "\n".join(l for l in s.splitlines() if l.strip())
A = sorted(glob.glob(T + "*.A.s1.ll"))
mov = [os.path.basename(a)[:-8] for a in A if norm(open(a).read()) != norm(open(a[:-8] + ".B.s1.ll").read())]
print(f"{len(A)} pairs; {len(mov)} stage-1 movers after normalisation")
for m in mov:
    print("S1MOVE", m)
