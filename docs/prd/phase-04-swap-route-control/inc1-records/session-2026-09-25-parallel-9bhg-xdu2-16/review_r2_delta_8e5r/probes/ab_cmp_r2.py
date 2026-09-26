#!/usr/bin/env python3
"""ab_cmp_r2.py <dirA> <dirB>: classify every module present in A (denominator printed).
Classes: same | A2D | D2A | CRASH (rc<0 or >=128 on either side) | STREAM (both rc 0, IR differs)
| STRING (both nonzero, stderr differs) | RCMOVE. Missing in B = MISSING."""
import os, sys, collections
A, B = sys.argv[1], sys.argv[2]
mods = sorted(f[:-3] for f in os.listdir(A) if f.endswith('.rc'))
cnt = collections.Counter(); rows = []
def rd(d, m, ext):
    p = os.path.join(d, m + ext)
    return open(p, 'rb').read() if os.path.exists(p) else None
for m in mods:
    ra, rb = rd(A, m, '.rc'), rd(B, m, '.rc')
    if rb is None: cnt['MISSING'] += 1; rows.append(('MISSING', m)); continue
    ra, rb = int(ra), int(rb)
    oa, ob = rd(A, m, '.out'), rd(B, m, '.out')
    ea, eb = rd(A, m, '.err'), rd(B, m, '.err')
    if ra == rb and oa == ob and ea == eb: cnt['same'] += 1; continue
    if ra >= 128 or rb >= 128 or ra < 0 or rb < 0: k = 'CRASH'
    elif ra == 0 and rb != 0: k = 'A2D'
    elif ra != 0 and rb == 0: k = 'D2A'
    elif ra == 0 and rb == 0: k = 'STREAM' if oa != ob else 'WARNMOVE'
    elif ea != eb: k = 'STRING'
    else: k = 'RCMOVE'
    cnt[k] += 1; rows.append((k, m, ra, rb))
print(f"denominator: {len(mods)} modules  A={A}  B={B}")
print("counts: " + " ".join(f"{k}={v}" for k, v in sorted(cnt.items())))
for r in rows: print("  " + "\t".join(map(str, r)))
