#!/usr/bin/env python3
"""equiv_tool_mutants.py — L10 for tools/trace_twin_equiv.py: mutate the CHECKER and
confirm its own boundary controls go red (an instrument nobody has tried to fool is
one nobody should trust). Each mutant must make `--selftest` exit non-zero; the NULL
mutant (a comment) must leave it green."""
import os
import subprocess
import sys
import tempfile

W = '/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a7712272d6ca568e9'
SRC = open(W + '/tools/trace_twin_equiv.py').read()

MUT = {
    # round 2 (bd rhk5): the RESULT-width conjunct of each rule, deleted — r1B's
    # U2/U4 spelled against the round-1 substring test, re-spelled here.
    'T9_rule1_no_result_width': ("            if result_width(t['sym']) != w:\n",
                                 "            if False:\n"),
    'T10_rule2_no_result_width': ("            if result_width(t['sym']) != w or x in t['args']:",
                                  "            if x in t['args']:"),
    'T11_compare_commutes': ("COMMUTATIVE = re.compile(r'^cq_template_(add|mul|xor|and|or)_i\\d+(_unc)?$')",
                             "COMMUTATIVE = re.compile(r'^cq_template_(add|mul|xor|and|or|icmp_\\w+)_i\\d+(_unc)?$')"),
    'T0_null': ('import os\n', 'import os  # null\n'),
    'T1_never_dependent': ('def dependent(e, f):\n    return bool(',
                           'def dependent(e, f):\n    return False and bool('),
    'T2_rule1_no_clobber_check': ('            if clobbered:\n                continue\n            hit = (i, j, u, f, b, t)',
                                  '            hit = (i, j, u, f, b, t)'),
    'T3_rule2_no_clobber_check': ('            if clobbered:\n                continue\n            hit2 = (i, j, u, f, x, t)',
                                  '            hit2 = (i, j, u, f, x, t)'),
    'T4_rz_is_read': ("    elif re.match(r'^cqrt_(ry|rz)_\\w+$', s) and len(a) == 2 and not s.endswith('_controlled'):\n        W(0)",
                      "    elif re.match(r'^cqrt_(ry|rz)_\\w+$', s) and len(a) == 2 and not s.endswith('_controlled'):\n        (R if s.startswith('cqrt_rz') else W)(0)"),
    'T5_unc_reads_out': ("        W(0)\n        for i in hpos:\n            if i != 0:\n                R(i)",
                         "        R(0)\n        for i in hpos:\n            if i != 0:\n                R(i)"),
    'T6_sub_commutes': ("COMMUTATIVE = re.compile(r'^cq_template_(add|mul|xor|and|or)_i\\d+(_unc)?$')",
                        "COMMUTATIVE = re.compile(r'^cq_template_(add|mul|xor|and|or|sub)_i\\d+(_unc)?$')"),
    'T7_no_literal_check': ("    lits = tuple((i, t) for i, t in enumerate(ev['args']) if not is_h(t))",
                            "    lits = tuple(i for i, t in enumerate(ev['args']) if not is_h(t))"),
    'T8_rule1_free_any_order': ("            i, u, f = ua[0], ua[2], ua[3]\n            t, un, fr = evs[i], evs[u], evs[f]\n            if not (is_fwd_producer(t['sym']) and not t['sym'].endswith('_unc')\n                    and t['ret'] == a and i < j):",
                                "            i, u, f = ua[0], ua[2], ua[3]\n            if evs[u]['sym'] == 'cqrt_free':\n                u, f = f, u\n            t, un, fr = evs[i], evs[u], evs[f]\n            if not (is_fwd_producer(t['sym']) and not t['sym'].endswith('_unc')\n                    and t['ret'] == a and i < j):"),
}

d = tempfile.mkdtemp(prefix='eqmut')
bad = 0
for name, (old, new) in MUT.items():
    n = SRC.count(old)
    if n != 1:
        print(f'{name}: anchor found {n} times — REFUSED')
        bad += 1
        continue
    p = os.path.join(d, name + '.py')
    open(p, 'w').write(SRC.replace(old, new, 1))
    r = subprocess.run(['python3', p, '--selftest'], capture_output=True, text=True)
    fails = [l.split('control ')[1].split()[0] for l in r.stdout.splitlines() if '[FAIL]' in l]
    want_green = name.startswith('T0')
    ok = (r.returncode == 0) if want_green else (r.returncode != 0)
    bad += 0 if ok else 1
    print(f"{name:28s} selftest rc={r.returncode} {'GREEN' if r.returncode == 0 else 'RED'} "
          f"{'(as required)' if ok else '!! WRONG'}  failing controls: {fails}")
print('ALL AS REQUIRED' if not bad else f'{bad} mutant(s) NOT as required')
sys.exit(1 if bad else 0)
