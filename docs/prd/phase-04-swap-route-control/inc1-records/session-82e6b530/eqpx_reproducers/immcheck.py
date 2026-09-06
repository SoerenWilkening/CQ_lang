#!/usr/bin/env python3
"""immcheck.py <lowered.ll> ...
Reports every `cqrt_{addc,xorc}_<W>(handle, imm)` whose IMMEDIATE slot holds a
QUANTUM RAIL, i.e. an SSA value defined by @cqrt_alloc_* or @cq_template_* (a
handle), rather than a Constant or a classical SSA computation.
Deliberately CONSERVATIVE: only a positively-identified rail producer counts."""
import re, sys
DEF = re.compile(r'^\s*(%[\w.]+)\s*=\s*(.*)$')
CALL = re.compile(r'call void @(cqrt_(?:addc|xorc)_[a-z0-9]+)\(i32 ([^,]+), i\d+ ([^)]+)\)')
for path in sys.argv[1:]:
    try: lines = open(path).read().splitlines()
    except OSError: print(f"{path}: MISSING"); continue
    defs = {}
    for ln in lines:
        m = DEF.match(ln)
        if m: defs[m.group(1)] = m.group(2)
    hits = []
    for i, ln in enumerate(lines, 1):
        m = CALL.search(ln)
        if not m: continue
        sym, h, imm = m.group(1), m.group(2).strip(), m.group(3).strip()
        if not imm.startswith('%'):
            continue                      # a Constant — fine
        d = defs.get(imm, '')
        if '@cqrt_alloc' in d or '@cq_template_' in d:
            hits.append((i, sym, h, imm, d.split('(')[0]))
    print(f"{path.split('/')[-1]}: railInImm={len(hits)}")
    for h in hits: print(f"   line {h[0]}: {h[1]}({h[2]}, {h[3]})   <- {h[3]} = {h[4]}")
