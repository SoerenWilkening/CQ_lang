#!/usr/bin/env python3
"""Track U R3 — ISOLATE THE PHI CLAUSE.

The U/Z sweep moves BOTH operands, so a moved row could be the SEED clause (which
round 2 already closed on 1922 fixtures) rather than the PHI clause.  This builds a
third corpus:

    SZ :  seed := the type's ZERO   (i.e. the seed clause already applied by hand)
          phi incoming := undef     (i.e. the phi clause NOT applied)

ORACLE(SZ) is therefore "what the pass does when ONLY the seed clause exists".
The PHI CLAUSE'S OWN POPULATION is exactly { rows : SUBJECT(U) != ORACLE(SZ) }.
"""
import sys, os, glob
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import phi_mutate as PM
from phi_census import strip_comment, THETA, PAIR, eligible

def mutate(src, dst):
    lines, thetas, el = eligible(src)
    if not el: return False
    carried = set(); [carried.update(e['carried']) for e in el]
    if not carried: return False
    out = list(lines); n = 0
    for i, raw in enumerate(lines):
        code = strip_comment(raw)
        m = THETA.match(code)
        if not m or m.group(1) not in carried: continue
        sp = PM.split_arg0(code)
        if sp is None: return False
        s, e2, ty, attrs, val = sp
        z = PM.zero_for(ty)
        if z is None: return False
        out[i] = code[:s] + (ty + (' ' + attrs if attrs else '') + ' ' + z) + code[e2:] + '\n'; n += 1
    for e in el:
        i = e['idx']; code = strip_comment(out[i])
        def rep(m):
            return m.group(0) if m.group(1).strip() in e['carried'] else '[ undef, %s ]' % m.group(2)
        nc = PAIR.sub(rep, code)
        if nc != code: out[i] = nc + '\n'; n += 1
    if n == 0: return False
    open(dst,'w').writelines(out)
    return os.path.getsize(dst) > 0

if __name__ == '__main__':
    src, outdir = sys.argv[1], sys.argv[2]
    os.makedirs(outdir, exist_ok=True); ok = 0
    for p in sorted(glob.glob(os.path.join(src,'*.ll'))):
        if mutate(p, os.path.join(outdir, os.path.basename(p))): ok += 1
    print("SZ mutants emitted:", ok)
