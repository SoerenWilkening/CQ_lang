#!/usr/bin/env python3
"""X2 (merge gate) — the composition Track U x Track F.

Track U normalizes an `undef`/`poison` cq_theta SEED to a concrete zero BEFORE
classification, so Track F's F2 (and its new phi-descendant conjunct) is handed
a seed population it never saw at HEAD.  This mutator rewrites the SEED operand
(arg 0) of every `@cq_theta_*` call in each F2-naming fixture to `undef`, so the
F2 family can be re-asked with BOTH changes present.  Emits one mutant per
fixture into the output dir."""
import re, sys, os, glob
outdir = sys.argv[1]
os.makedirs(outdir, exist_ok=True)
pat = re.compile(r'(@cq_theta_[a-z0-9]+\()([^,()]+?)(, double)')
n = 0
for f in sorted(glob.glob('ir-pass/test/*.ll')):
    txt = open(f, errors='replace').read()
    if 'state prep seed is proven equal to the condition register' not in txt:
        continue
    def sub(m):
        head, arg, tail = m.group(1), m.group(2), m.group(3)
        # arg looks like "i32 %u0" / "i32 6" / "i1 true" — keep the type, undef the value
        parts = arg.strip().split()
        if len(parts) < 2:
            return m.group(0)
        return head + parts[0] + ' undef' + tail
    new, k = pat.subn(sub, txt)
    if k == 0:
        continue
    open(os.path.join(outdir, os.path.basename(f)), 'w').write(new)
    n += 1
print("mutants written:", n)
