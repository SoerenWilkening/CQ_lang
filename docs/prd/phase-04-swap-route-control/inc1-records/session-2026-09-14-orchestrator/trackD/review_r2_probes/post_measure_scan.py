#!/usr/bin/env python3
"""§14 POPULATION: golden traces in which a rail handle is MEASURED and then acted on
again.  Those are the streams the 2026-09-14 'a measured name needs a fresh alloc'
ruling would change.  Reads the committed .expected.log goldens — the contract itself."""
import re, glob, os, sys, collections
gate = re.compile(r'^(cqrt_[a-z0-9_]+|cq_template_[A-Za-z0-9_]+)\((.*?)\)(?: -> (\S+))?\s*$')
hits = collections.OrderedDict()
tot = 0
for f in sorted(glob.glob('tests/e2e/*.expected.log')):
    tot += 1
    measured = {}          # handle -> line no of its measure
    after = collections.defaultdict(list)
    for i, ln in enumerate(open(f, errors='replace')):
        ln = ln.strip()
        m = gate.match(ln)
        if not m: continue
        sym, args, ret = m.group(1), m.group(2), m.group(3)
        hs = re.findall(r'\bh(\d+)\b', args)
        if sym.startswith('cqrt_measure_'):
            if hs: measured.setdefault('h'+hs[0], i)
            continue
        if sym.startswith('cqrt_free'):
            continue                      # a free is not a re-use of the STATE
        for h in ('h'+x for x in hs):
            if h in measured and i > measured[h]:
                after[h].append((i, sym))
    if after:
        hits[f] = after
for f, a in hits.items():
    n = sum(len(v) for v in a.values())
    ex = next(iter(a.items()))
    print(f"{os.path.basename(f)} | {len(a)} handle(s), {n} post-measure op(s) | e.g. {ex[0]} -> {ex[1][0][1]}")
print(f"\n# {len(hits)} of {tot} goldens contain a post-measure re-use", file=sys.stderr)
