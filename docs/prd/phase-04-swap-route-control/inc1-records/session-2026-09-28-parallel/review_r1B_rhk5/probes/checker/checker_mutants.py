#!/usr/bin/env python3
"""r1B checker mutants for tools/trace_twin_equiv.py — conjuncts/rows the implementer's
8 mutants did not touch. Each mutant: does `--selftest` go RED? And does it flip any
verdict on the three committed e2e gate pairs? U0 is the NULL control (must be GREEN
and flip nothing). Run from the worktree root."""
import os, subprocess, sys, tempfile
W = os.getcwd()
SRC = open(os.path.join(W, 'tools/trace_twin_equiv.py')).read()
PAIRS = [('tests/e2e/slice_spec_clone_read_in_window.expected.log', 'tests/e2e/slice_spec_clone_read_in_window_twin.expected.log'),
         ('tests/e2e/slice_spec_clone_consumes_chain_rail.expected.log', 'tests/e2e/slice_spec_clone_consumes_chain_rail_twin.expected.log'),
         ('tests/e2e/slice_spec_clone_read_nested.expected.log', 'tests/e2e/slice_spec_clone_read_nested_twin.expected.log')]
MUT = {
 'U0_null': ('import re\n', 'import re  # null\n'),
 'U1_r1_scratch_multiuse': ("            if len(ua) != 4 or ua[1] != j + 1:\n", "            if len(ua) < 4 or ua[1] != j + 1:\n"),
 'U2_r1_no_width_check': ("            if ('_' + w + '_') not in (t['sym'] + '_'):\n                continue            # the copy width",
                          "            if False:\n                continue            # the copy width"),
 'U3_r1_alloc_any_init': ("            if not (al['sym'].startswith('cqrt_alloc_') and al['args'] == ['0']",
                          "            if not (al['sym'].startswith('cqrt_alloc_') and len(al['args']) == 1"),
 'U4_r2_x_may_be_arg': ("            if ('_' + w + '_') not in (t['sym'] + '_') or x in t['args']:",
                        "            if ('_' + w + '_') not in (t['sym'] + '_'):"),
 'U5_r2_copy_not_second_use': ("            if len(uc) != 4 or uc[1] != j:", "            if len(uc) != 4 or j not in uc:"),
 'U6_cswap_reads_targets': ("        R(0); W(1); W(2)\n", "        R(0); R(1); R(2)\n"),
 'U7_toffoli_reads_target': ("    elif s == 'cqrt_toffoli' and len(a) == 3:\n        R(0); R(1); W(2)",
                             "    elif s == 'cqrt_toffoli' and len(a) == 3:\n        R(0); R(1); R(2)"),
 'U8_cnot_reads_target': ("    elif s == 'cqrt_cnot' and len(a) == 2:\n        R(0); W(1)",
                          "    elif s == 'cqrt_cnot' and len(a) == 2:\n        R(0); R(1)"),
 'U9_crot_reads_target': ("            R(0)\n        W(1)\n", "            R(0)\n        R(1)\n"),
 'U10_ccopy_reads_dst': ("        R(0); R(1); W(2)\n    elif s.startswith('cqrt_copy_') and len(a) == 2:",
                         "        R(0); R(1); R(2)\n    elif s.startswith('cqrt_copy_') and len(a) == 2:"),
 'U11_addc_reads': ("    elif re.match(r'^cqrt_(addc|xorc)_\\w+$', s) and len(a) == 2:\n        W(0)",
                    "    elif re.match(r'^cqrt_(addc|xorc)_\\w+$', s) and len(a) == 2:\n        R(0)"),
 'U12_measure_reads': ("    elif s.startswith('cqrt_measure_') and len(a) == 1:\n        W(0)",
                       "    elif s.startswith('cqrt_measure_') and len(a) == 1:\n        R(0)"),
 'U13_no_injectivity': ("            elif y in bwd:\n", "            elif False:\n"),
 'U14_icmp_commutes': ("COMMUTATIVE = re.compile(r'^cq_template_(add|mul|xor|and|or)_i\\d+(_unc)?$')",
                       "COMMUTATIVE = re.compile(r'^cq_template_(add|mul|xor|and|or|icmp_\\w+)_i\\d+(_unc)?$')"),
}
d = tempfile.mkdtemp(prefix='r1Beqmut')
for name, (old, new) in MUT.items():
    n = SRC.count(old)
    if n != 1:
        print(f'{name}: anchor x{n} — REFUSED'); continue
    p = os.path.join(d, 'trace_twin_equiv.py'); open(p, 'w').write(SRC.replace(old, new, 1))
    r = subprocess.run(['python3', p, '--selftest'], capture_output=True, text=True)
    fails = [l.split('control ')[1].split()[0] for l in r.stdout.splitlines() if '[FAIL]' in l]
    flips = []
    for s, t in PAIRS:
        q = subprocess.run(['python3', p, '--quiet-controls', s, t], capture_output=True, text=True)
        v = q.stdout.strip().splitlines()[-1] if q.stdout.strip() else '?'
        if 'EQUIV' not in v or q.returncode != 0: flips.append(os.path.basename(s))
    print(f"{name:28s} selftest {'GREEN' if r.returncode == 0 else 'RED  '} fails={fails} gate-flips={flips}")

# --- which r1B attack rows (attack_checker.py) KILL each mutant (a row whose verdict flips)
print('\n-- r1B attack rows vs each mutant (rows that flip = kills) --')
A = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'attack_checker.py')
base = subprocess.run(['python3', A], capture_output=True, text=True, env=dict(os.environ, CQ_TOOLS=os.path.join(W, 'tools'))).stdout.splitlines()
for name, (old, new) in MUT.items():
    if SRC.count(old) != 1: continue
    md = tempfile.mkdtemp(prefix='r1Bm'); open(os.path.join(md, 'trace_twin_equiv.py'), 'w').write(SRC.replace(old, new, 1))
    out = subprocess.run(['python3', A], capture_output=True, text=True, env=dict(os.environ, CQ_TOOLS=md)).stdout.splitlines()
    kills = [b.split()[0] for b, o in zip(base, out) if b.split()[:2] != o.split()[:2]]
    print(f"{name:28s} killed by r1B rows: {kills}")
