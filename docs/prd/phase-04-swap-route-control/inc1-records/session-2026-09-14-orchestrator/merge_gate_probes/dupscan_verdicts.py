#!/usr/bin/env python3
"""MERGE-GATE duplicate-body scan (L8), extended from trackF/fix_r2_probes/dupscan.py.

The raw group COUNT is not the property that matters: a duplicate body is
harmless if both copies claim the SAME verdict.  What L8 warns about is a
`git mv`'d fixture RESURRECTED by a merge, so that ONE module lives under TWO
names with CONTRADICTORY verdicts.  This script reports, for every
duplicate-body group under all four normalisations, the per-file CLAIMED
verdict read off the RUN lines (a `not %cq-opt` RUN line == a DECLINE fixture,
a bare `%cq-opt` RUN line == an ACCEPT fixture) and flags groups that mix them.
Run from a checkout root."""
import hashlib, glob, collections, re, sys

files = sorted(glob.glob('ir-pass/test/*.ll'))

def body(f, col0, drop_blank):
    out = []
    for ln in open(f, errors='replace').read().split('\n'):
        if (ln.startswith(';') if col0 else ln.lstrip().startswith(';')):
            continue
        if drop_blank and ln.strip() == '':
            continue
        out.append(ln)
    return hashlib.sha256('\n'.join(out).encode()).hexdigest()

def claimed_verdict(f):
    """DECLINE if any RUN line pipes cq-opt through `not`, ACCEPT if any RUN
    line runs cq-opt bare, BOTH if both, NONE if no cq-opt RUN line."""
    txt = open(f, errors='replace').read()
    runs = [m.group(0) for m in re.finditer(r'^\s*;\s*RUN:.*$', txt, re.M)]
    dec = any(re.search(r'\bnot\b[^|]*%cq-opt', r) for r in runs)
    acc = any(re.search(r'%cq-opt', r) and not re.search(r'\bnot\b[^|]*%cq-opt', r)
              for r in runs)
    if dec and acc: return 'BOTH'
    if dec: return 'DECLINE'
    if acc: return 'ACCEPT'
    return 'NONE'

print("fixtures:", len(files))
contradictory_any = {}
for col0 in (False, True):
    for db in (False, True):
        g = collections.defaultdict(list)
        for f in files:
            g[body(f, col0, db)].append(f)
        dups = {k: v for k, v in g.items() if len(v) > 1}
        tag = f"comment={'col0' if col0 else 'lstrip'}, blanks={'DROPPED' if db else 'KEPT'}"
        contra = []
        for k, v in sorted(dups.items()):
            verds = {f: claimed_verdict(f) for f in v}
            if len(set(verds.values())) > 1:
                contra.append((k, verds))
                contradictory_any[k] = verds
        print(f"  {tag:42s} groups={len(dups):2d}  CONTRADICTORY-VERDICT groups={len(contra)}")
        for k, v in sorted(dups.items()):
            verds = {f: claimed_verdict(f) for f in v}
            mark = '  <<< CONTRADICTORY' if len(set(verds.values())) > 1 else ''
            print(f"      [{k[:12]}]{mark}")
            for f, ver in sorted(verds.items()):
                print(f"         {ver:8s} {f}")

print()
print("TOTAL CONTRADICTORY-VERDICT groups across all four normalisations:",
      len(contradictory_any))
sys.exit(1 if contradictory_any else 0)
