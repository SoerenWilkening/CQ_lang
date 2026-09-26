#!/usr/bin/env python3
"""movcat.py ABFILE : mover counts by kind x source (lit / P_ records / Q_ round-2 probes /
E_ e2e / M_ multi-TU), from an ab.py output. (movers.py lumps Q_ into "lit".)"""
import collections
import sys

c = collections.Counter()
den = None
for l in open(sys.argv[1]):
    if l.startswith('denominator'):
        den = l.split()[0]
        continue
    if l.startswith('summary'):
        continue
    k, p = l.split('\t')[:2]
    n = p.split('/')[-1]
    src = 'lit' if '/ir-pass/test/' in p else n.split('_')[0] + '_'
    c[(k, src)] += 1
print(den, 'movers=%d' % sum(c.values()))
for (k, s), v in sorted(c.items()):
    print(f'  {k:7s} {s:4s} {v}')
