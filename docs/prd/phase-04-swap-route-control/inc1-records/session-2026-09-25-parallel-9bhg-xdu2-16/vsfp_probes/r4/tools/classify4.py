#!/usr/bin/env python3
"""classify4.py : classify every REVIEW-PROBE (R_) mover of ORACLE → round 4 (ab7_final.txt):
  * a probe of r2A/r2B/r3A/r3B vsfp → its row in the round-4 battery (r4bat_r4f.txt), keyed by
    the probe (the reviewers' `.O1`/`.s1` stage-1 copies map to the probe they came from);
  * a probe that is itself a TWIN in the battery → TWIN (its own trace is the reference; listed);
  * r1A/r1B vsfp and r2A_9bhg probes that moved NEITHER round 2 → 3 (ab5_delta) NOR round 3 → 4
    (ab7_delta) keep round 2's twin classification (twin2_final.txt);
  * anything else → UNCLASSIFIED (listed).
Prints class counts per source, then every row that is not TRACE-IDENT / DECL-SAME / ORACLE-SAME."""
import collections
import pathlib
import re

V = pathlib.Path(__file__).parent


def movers(f):
    out = {}
    for l in open(V / f):
        if l.startswith(('denominator', 'summary')):
            continue
        k, p = l.split('\t')[:2]
        out[p.split('/')[-1]] = k
    return out


fin = movers('ab7_final.txt')
d23 = movers('ab5_delta.txt')
d34 = movers('ab7_delta.txt')
bat, twins = {}, set()
for l in open(V / 'r4bat_r4f.txt'):
    m = re.match(r'\[\S+\] (\S+) vs (\S+): (\S+)', l)
    if m:
        bat[m.group(1)] = m.group(3)
        twins.add(m.group(2))
    m = re.match(r'\[\S+\] single (\S+): (\S+)', l)
    if m:
        bat[m.group(1)] = m.group(2)
r2 = {}
for l in open(V / 'twin2_final.txt'):
    p = l.rstrip('\n').split('\t')
    if len(p) >= 3:
        r2[p[1]] = p[2]
DIRMAP = {'review_r2A_vsfp': 'r3p', 'review_r2B_vsfp': 'r3p', 'review_r3A_vsfp': 'r4a', 'review_r3B_vsfp': 'r4b'}
cnt, bad = collections.Counter(), []
for name, kind in sorted(fin.items()):
    if not name.startswith('R_'):
        continue
    stem = name[2:].replace('.s1.ll', '')
    d, rest = stem.split('__', 1)
    if d in DIRMAP:
        isll = rest.startswith('LL_')
        p = re.sub(r'^(LL_)?probes_(src_)?', '', rest)
        p = re.sub(r'\.(O1|s1|subject\.lowered)$', '', p)
        base = DIRMAP[d]
        keys = [f'{base}/{p}.c', f'{base}/{p}.ll'] if isll else [f'{base}/{p}.c']
        c = next((bat[k] for k in keys if k in bat), None)
        if c is None and any(k in twins for k in keys + [f'{base}/{p}.c']):
            c = 'TWIN'
        src = 'battery'
    else:
        src = 'round2'
        c = None if (name in d23 or name in d34) else r2.get(('P_' if d == 'review_r2A_9bhg' else 'Q_') + stem)
    c = c or 'UNCLASSIFIED'
    cnt[(src, kind, c)] += 1
    if c not in ('TRACE-IDENT', 'TRACE-IDENT(auto)', 'DECL-SAME', 'DECL-SAME(auto)', 'ORACLE-SAME'):
        bad.append((kind, name, c))
for (s, k, c), v in sorted(cnt.items()):
    print(f'{v:4d} {s:8s} {k:6s} {c}')
print('--- rows not TRACE-IDENT / DECL-SAME / ORACLE-SAME:')
for b in bad:
    print(*b)
