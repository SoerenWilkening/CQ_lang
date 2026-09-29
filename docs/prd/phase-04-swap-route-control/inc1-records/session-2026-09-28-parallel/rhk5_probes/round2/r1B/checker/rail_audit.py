#!/usr/bin/env python3
"""rail_audit.py TRACE RAIL... — for each rail: every line that WRITES it (per
trace_twin_equiv's effects model), its last READ, and whether the borrowed parents of
its mint are written between the mint and the rail's `_unc`. r1B, bd rhk5."""
import os, sys
sys.path.insert(0, os.environ.get('CQ_TOOLS', 'tools'))
import trace_twin_equiv as T
evs = T.parse(open(sys.argv[1]).read().splitlines())
for e in evs:
    try: T.effects(e)
    except T.Refused: e['R'], e['W'] = set(), set(e['args']) | ({e['ret']} if e['ret'] else set())
for r in sys.argv[2:]:
    writes = [(i + 1, e['line']) for i, e in enumerate(evs) if r in e['W']]
    reads = [i + 1 for i, e in enumerate(evs) if r in e['R']]
    mint = writes[0][0]
    unc = next((i for i, l in writes if l.endswith(')') and '_unc(' + r + ',' in l), None)
    free = next((i for i, l in writes if l == f'cqrt_free({r})'), None)
    parents = [a for a in evs[mint - 1]['args'] if T.is_h(a)]
    pw = {p: [i + 1 for i, e in enumerate(evs) if p in e['W'] and mint < i + 1 < (unc or 10**9)] for p in parents}
    last_read_before_unc = max([x for x in reads if unc is None or x < unc] or [0])
    reads_after_unc = [x for x in reads if unc and x > unc]
    print(f"{r}: mint L{mint}, writes {[i for i,_ in writes]}, last read L{last_read_before_unc}, "
          f"unc L{unc}, free L{free}, reads-after-unc {reads_after_unc}, parents {parents} "
          f"written in (mint,unc): {pw}")
