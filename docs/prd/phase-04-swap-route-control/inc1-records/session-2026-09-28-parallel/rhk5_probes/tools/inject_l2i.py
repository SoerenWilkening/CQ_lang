#!/usr/bin/env python3
"""inject_l2i.py LOWERED.ll — mutation check of spec_accept_clone_read_hoisted_rail_in_
rolled_loop.ll's prefixes (Rule 12: validate by mutation, record the MISSED count).
Each injection edits the round-2 lowered stream; every prefix set must then FAIL.
A NULL injection (no edit) must PASS every prefix. Prints one line per mutation."""
import os
import subprocess
import sys
import tempfile

W = '/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a7712272d6ca568e9'
FC = '/usr/local/opt/llvm@19/bin/FileCheck'
FX = W + '/ir-pass/test/spec_accept_clone_read_hoisted_rail_in_rolled_loop.ll'
PREFIXES = ['EXIT', 'BODY', 'ONCE']
src = open(sys.argv[1]).read()
UNC = '  call void @cq_template_mul_i32_hl_unc(i32 %h_op, i32 %h, i32 3)\n'
FREE = '  call void @cqrt_free(i32 %h_op)\n'
CLONE = '  %9 = tail call i32 @__cq_q_h_10(i32 noundef 0, i32 noundef %h_op) #5\n'
RY = '  call void @cqrt_ry_i32(i32 %h, double 9.000000e-01)\n'
assert src.count(UNC) == 1 and src.count(CLONE) == 1 and src.count(RY) == 1


def m_null(s):
    return s


def m_discharge_in_body(s):          # the discharge moved INTO the rolled body
    return s.replace(UNC + FREE, '', 1).replace(CLONE, CLONE + UNC + FREE, 1)


def m_extra_in_body(s):              # a second discharge inside the body
    return s.replace(CLONE, CLONE + UNC, 1)


def m_after_ry(s):                   # the discharge after the trailing Ry
    return s.replace(UNC + FREE + RY, RY + UNC + FREE, 1)


def m_dropped(s):                    # the discharge dropped (a leak)
    return s.replace(UNC + FREE, '', 1)


def m_free_dropped(s):               # the adjoint kept, the free dropped
    return s.replace(UNC + FREE, UNC, 1)


MUTS = [m_null, m_discharge_in_body, m_extra_in_body, m_after_ry, m_dropped, m_free_dropped]
missed = 0
for m in MUTS:
    text = m(src)
    fd, p = tempfile.mkstemp(suffix='.ll')
    os.write(fd, text.encode())
    os.close(fd)
    fails = [pre for pre in PREFIXES
             if subprocess.run([FC, FX, f'--check-prefix={pre}', f'--input-file={p}'],
                               capture_output=True).returncode != 0]
    os.unlink(p)
    if m is m_null:
        verdict = 'OK (null passes)' if not fails else f'!! NULL FAILED {fails}'
    else:
        verdict = f'caught by {fails}' if fails else 'MISSED'
        missed += not fails
    print(f'{m.__name__:24s} {verdict}')
print(f'MISSED {missed} of {len(MUTS) - 1}')
