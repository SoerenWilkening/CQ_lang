#!/usr/bin/env python3
"""u12_u13_probe.py — which candidate pairs PIN the checker's measure-as-write (U12) and
renaming-injectivity (U13) conjuncts? A pair pins a conjunct iff the shipped checker
says DIFF and the one-line mutant (r1B's U12/U13 spelling, applied to the current
source) says EQUIV. Candidates: r2B's `width_battery.py` rows and r2B's alloc-free cnot
U13 pair (REVIEW.md Q5)."""
import importlib.util
import os
import sys
import tempfile

W = '/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a7712272d6ca568e9'
SRC = open(W + '/tools/trace_twin_equiv.py').read()
MUT = {
    'shipped': None,
    'U12': ("    elif s.startswith('cqrt_measure_') and len(a) == 1:\n        W(0)",
            "    elif s.startswith('cqrt_measure_') and len(a) == 1:\n        R(0)"),
    'U13': ("            elif y in bwd:\n", "            elif False:\n"),
}


def load(name, mut):
    s = SRC if mut is None else SRC.replace(*mut, 1)
    assert mut is None or SRC.count(mut[0]) == 1, name
    d = tempfile.mkdtemp()
    p = os.path.join(d, f'tte_{name}.py')
    open(p, 'w').write(s)
    spec = importlib.util.spec_from_file_location(f'tte_{name}', p)
    m = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(m)
    return m


def t(*L):
    return '\n'.join(L) + '\n'


PAIRS = {
    'r2B_U12_measure_past_copysrc': (
        t('cqrt_alloc_i32(5) -> h0', 'cqrt_alloc_i32(0) -> h1',
          'cqrt_copy_i32(h0, h1)', 'cqrt_measure_i32(h0) -> 0', 'cqrt_free(h1)'),
        t('cqrt_alloc_i32(5) -> h0', 'cqrt_alloc_i32(0) -> h1',
          'cqrt_measure_i32(h0) -> 0', 'cqrt_copy_i32(h0, h1)', 'cqrt_free(h1)')),
    'r2B_U13_measure_alloc_first': (
        t('cqrt_alloc_i32(0) -> h0', 'cqrt_alloc_i32(0) -> h1',
          'cqrt_measure_i32(h0) -> 0', 'cqrt_measure_i32(h1) -> 0'),
        t('cqrt_alloc_i32(0) -> h0', 'cqrt_alloc_i32(0) -> h1',
          'cqrt_measure_i32(h0) -> 0', 'cqrt_measure_i32(h0) -> 0')),
    'r2B_U13_cnot_unbound': (
        t('cqrt_cnot(h0, h1)', 'cqrt_cnot(h0, h2)'),
        t('cqrt_cnot(h0, h1)', 'cqrt_cnot(h0, h1)')),
}
mods = {k: load(k, v) for k, v in MUT.items()}
for name, (a, b) in PAIRS.items():
    row = []
    for k, m in mods.items():
        try:
            v = m.compare_text(a, b)[0]
        except Exception as e:           # noqa: BLE001
            v = 'REFUSED' if type(e).__name__ == 'Refused' else f'ERR:{type(e).__name__}'
        row.append(f'{k}={v}')
    print(f'{name:32s} ' + '  '.join(row))
