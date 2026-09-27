#!/usr/bin/env python3
"""classify3.py : classify every REVIEW-PROBE (R_) mover of the ORACLE → round-3 A/B
(ab5_final.txt) against its twin, mechanically:
  * a probe of review_r2A_vsfp / review_r2B_vsfp → its row in the round-3 battery
    (r3bat_r3a.txt; .LL stage-1 copies map to the probe stem; a T-twin probe → the
    hand-check table below);
  * a probe of review_r1A_vsfp / review_r1B_vsfp / review_r2A_9bhg that did NOT move
    round 2 → round 3 (ab5_delta.txt) has round 2's stream, so round 2's twin
    classification (twin2_final.txt, keyed by the same source) stands;
  * anything else → UNCLASSIFIED (must be 0).
Prints class counts per source and every UNCLASSIFIED / non-identical row."""
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


fin = movers('ab5_final.txt')
delta = movers('ab5_delta.txt')
bat = {}
for l in open(V / 'r3bat_r3a.txt'):
    m = re.match(r'r3p/\[r3a\] (\S+) vs \S+: (\S+)', l)
    if m:
        bat[m.group(1)] = m.group(2)
    m = re.match(r'r3p/\[r3a\] single (\S+): (\S+)', l)
    if m:
        bat[m.group(1)] = m.group(2)
HAND = {'k2T': 'TRACE-IDENT', 'k3T': 'TRACE-IDENT', 'k4T': 'TRACE-IDENT', 'k5T': 'TRACE-IDENT',
        'k1T': 'TRACE-IDENT'}  # pp.sh r3a r3p kNT:kNF (k1T:gTA) — the literal-inlined twins vs the fenv twins
r2 = {}
for l in open(V / 'twin2_final.txt'):
    parts = l.rstrip('\n').split('\t')
    if len(parts) >= 3:
        r2[parts[1]] = parts[2]
# round-2 names: P_review_r2A_9bhg__probes_src_X / Q_review_r1A_vsfp__probes_src_X / Q_review_r1B_vsfp__...
cnt = collections.Counter()
bad = []
for name, kind in sorted(fin.items()):
    if not name.startswith('R_'):
        continue
    stem = name[2:].replace('.s1.ll', '')
    d, rest = stem.split('__', 1)
    if d in ('review_r2A_vsfp', 'review_r2B_vsfp'):
        p = re.sub(r'^(LL_)?probes_(src_)?', '', rest)
        p = p.replace('.O1', '')
        c = bat.get(p) or HAND.get(p)
        if p == 'fwa1_stale_taint_redgreen':
            c = bat.get('stale3c')
        src = 'battery'
    else:
        src = 'round2'
        if name in delta:
            c = None
        else:
            key = ('P_' if d == 'review_r2A_9bhg' else 'Q_') + stem
            c = r2.get(key)
    c = c or 'UNCLASSIFIED'
    cnt[(src, kind, c)] += 1
    if c not in ('TRACE-IDENT', 'TRACE-IDENT(auto)', 'DECL-SAME', 'DECL-SAME(auto)', 'ORACLE-SAME'):
        bad.append((kind, name, c))
for (s, k, c), v in sorted(cnt.items()):
    print(f'{v:4d} {s:8s} {k:6s} {c}')
print('--- rows not TRACE-IDENT / DECL-SAME:')
for b in bad:
    print(*b)
