#!/usr/bin/env python3
"""Duplicate-body scan over ir-pass/test/*.ll under FOUR normalisations, to
reconcile the three numbers on record (implementer 7/9, round-1 reviewer 8).
Run from a checkout root:  python3 dupscan.py"""
import hashlib, glob, os, collections, sys
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
print("fixtures:", len(files))
for col0 in (False, True):
    for db in (False, True):
        g = collections.defaultdict(list)
        for f in files: g[body(f, col0, db)].append(f)
        d = {k: v for k, v in g.items() if len(v) > 1}
        tag = f"comment={'col0' if col0 else 'lstrip'}, blanks={'DROPPED' if db else 'KEPT'}"
        print(f"  {tag:40s} groups={len(d)}")
