#!/usr/bin/env python3
"""compare_batteries.py — one row per reviewer probe: ORACLE | ROUND 1 | ROUND 2, each
as `verdict/warn/dirty` (+ trace sha), then the round-2 twin verdict, and two flags:
`=O` when round 2's subject trace is byte-identical to the oracle's, `=R1` when it is
byte-identical to round 1's. Reads battery_{oracle,subject_v2,r2}.txt."""
import os
import re

H = os.path.dirname(os.path.abspath(__file__))


def load(tag):
    rows = {}
    for line in open(os.path.join(H, f'battery_{tag}.txt')):
        if '|' not in line:
            continue
        name, rest = line.split('|', 1)
        parts = rest.split('||')
        subj = parts[0].strip()
        twin = parts[1].strip() if len(parts) > 1 else ''
        eq = parts[2].strip() if len(parts) > 2 else ''
        rows[name.strip()] = (subj, twin, eq)
    return rows


def short(s):
    if s.startswith('ACCEPT'):
        w = re.search(r'warn=(\d+)', s).group(1)
        d = re.search(r'dirty=(\d+)', s)
        d = d.group(1) if d else '?'
        t = re.search(r'trace=(\w+)', s)
        c = re.search(r'opt-user=([\d.]+)s', s)
        tail = t.group(1)[:6] if t else (f'{c.group(1)}s' if c else '')
        return f'A w{w} d{d} {tail}'
    if s.startswith('DECLINE'):
        return 'DECLINE'
    return s.split()[0] if s else '-'


O, R1, R2 = load('oracle'), load('subject_v2'), load('r2')
print(f"{'probe':30s} {'ORACLE':18s} {'ROUND 1':18s} {'ROUND 2':18s} {'r2 twin':10s} flags")
for name in O:
    o, r1, r2 = O[name][0], R1.get(name, ('',))[0], R2.get(name, ('',))[0]
    flags = []
    to, t1, t2 = (re.search(r'trace=(\w+)', x) for x in (o, r1, r2))
    if t2 and to and t2.group(1) == to.group(1):
        flags.append('=O')
    if t2 and t1 and t2.group(1) == t1.group(1):
        flags.append('=R1')
    if o.startswith('DECLINE') and r2.startswith('DECLINE') and o == r2:
        flags.append('=O(decl)')
    eq = R2.get(name, ('', '', ''))[2]
    print(f"{name:30s} {short(o):18s} {short(r1):18s} {short(r2):18s} {eq[:10]:10s} {' '.join(flags)}")
