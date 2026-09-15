#!/usr/bin/env python3
"""Attribute corpus-sweep movers to a track BY STRING.

Rows are `rel|A|<ir-sha16>|` or `rel|D<exit>|<full-stderr-sha16>|<regex-tag>`.
An ACCEPT→ACCEPT pair whose IR hash moved is a mover too (a STREAM move), and a
DECLINE→DECLINE pair whose FULL-STDERR hash moved is a mover too — that second one
is invisible to the shared `corpus.sh` tag regex (PROTOCOL S3) and is the reason
this sweep hashes the whole of stderr.

⚠ An unattributable mover is a FINDING, printed as such and counted.
"""
import sys, collections

def load(p):
    d = {}
    for ln in open(p):
        ln = ln.rstrip('\n')
        if not ln: continue
        parts = ln.split('|')
        d[parts[0]] = tuple(parts[1:])
    return d

base_p, subj_p, base_lbl, subj_lbl = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
base, subj = load(base_p), load(subj_p)
if not base or not subj:
    print("REFUSE: an empty sweep file"); sys.exit(2)
common = sorted(set(base) & set(subj))
if len(common) < 100:
    print(f"REFUSE: only {len(common)} common rows"); sys.exit(2)

# track signatures, BY STRING, from each branch's own brief
SIG = [
  ("S'  (dephase-fence-r2, bd c767/7845/2g52)",
   lambda b,s: 'rolled body leaks a rail entangled with a rotated register' in (s[2] if len(s)>2 else '')
               or 'rotated after the loop' in (b[2] if len(b)>2 else '')),
  ("T   (inloop-pairing, bd tu9q)",
   lambda b,s: 'round-1 iteration-local marking falsified by round-2 taint' in (s[2] if len(s)>2 else '')),
]

buckets = collections.defaultdict(list)
for k in common:
    b, s = base[k], subj[k]
    if b == s: continue
    bv, sv = b[0], s[0]
    bs = b[2] if len(b) > 2 else ''
    ss = s[2] if len(s) > 2 else ''
    kind = f"{'A' if bv=='A' else 'D'}->{'A' if sv=='A' else 'D'}"
    if bv == 'A' and sv == 'A': kind = 'A->A (STREAM MOVED)'
    if bv != 'A' and sv != 'A' and b[1] != s[1]: kind = 'D->D (STDERR MOVED)'
    who = None
    for name, f in SIG:
        try:
            if f(b, s): who = name; break
        except Exception: pass
    if who is None:
        who = '⚠ UNATTRIBUTED — FINDING'
    buckets[(who, kind)].append((k, bs, ss))

print(f"corpus: {len(common)} common rows ({base_lbl} vs {subj_lbl}); "
      f"base-only {len(set(base)-set(subj))}, subj-only {len(set(subj)-set(base))}")
tot = sum(len(v) for v in buckets.values())
print(f"MOVERS: {tot}\n")
find = 0
for (who, kind), rows in sorted(buckets.items()):
    print(f"── {who} | {kind} | {len(rows)} row(s)")
    if 'UNATTRIB' in who: find += len(rows)
    for k, bs, ss in rows[:12]:
        print(f"     {k}\n        {base_lbl}: {bs or '(accept)'}\n        {subj_lbl}: {ss or '(accept)'}")
    if len(rows) > 12: print(f"     … and {len(rows)-12} more")
    print()
print(f"UNATTRIBUTED MOVERS (FINDINGS): {find}")
sys.exit(1 if find else 0)
