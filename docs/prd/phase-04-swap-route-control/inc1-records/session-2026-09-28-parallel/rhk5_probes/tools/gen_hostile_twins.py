#!/usr/bin/env python3
"""gen_hostile_twins.py — derive the three extra hostile-twin LEAK fixtures from
spec_leak_clone_read_twin_writes_arg.ll (bd rhk5). Each pre-supplied twin writes its
borrowed argument `%k` by a different route, so a mutant that admits that route turns
exactly its own file red."""
import os

W = '/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a7712272d6ca568e9'
T = W + '/ir-pass/test/'
base = open(T + 'spec_leak_clone_read_twin_writes_arg.ll').read()
lines = base.splitlines()
b0 = next(i for i, l in enumerate(lines) if l.startswith('declare i32 @cq_theta_si32'))
c0 = next(i for i, l in enumerate(lines) if l.startswith('; The chain is standing'))
body = '\n'.join(lines[b0:c0]) + '\n'
OLD = ('define internal void @__cq_q_g_1_unc(i32 %out, i32 %k) {\n'
       '  call void @cqrt_x(i32 %k)\n'
       '  %h_op = call i32 @cq_template_mul_i32_hl(i32 %k, i32 5)')
assert OLD in body
body = body.replace('; The PRE-SUPPLIED twin: it WRITES `%k` (one `cqrt_x`, never undone).',
                    '; The PRE-SUPPLIED twin: it WRITES `%k`.')

V = {
    'copy_dst': (
        'a CONTROLLED-COPY DESTINATION (`cqrt_copy_i32_controlled(%out, %h_op, %k)` '
        'writes `%k`)',
        "clause (B3') admits a controlled copy's CONTROL and SOURCE only; a mutant that "
        'admits its destination turns this file red',
        'define internal void @__cq_q_g_1_unc(i32 %out, i32 %k) {\n'
        '  %h_op = call i32 @cq_template_mul_i32_hl(i32 %k, i32 5)\n'
        '  call void @cqrt_copy_i32_controlled(i32 %out, i32 %h_op, i32 %k)',
        'declare void @cqrt_copy_i32_controlled(i32, i32, i32)\n',
        'call void @cqrt_copy_i32_controlled(i32 %out, i32 %h_op, i32 %k)'),
    'unc_out': (
        'the OUT slot of an adjoint (`cq_template_mul_i32_hl_unc(%k, %h_op, 5)` XORs onto '
        '`%k`)',
        "clause (B2) admits an adjoint's READ slots only (`isUncHandleSlot` refuses slot "
        '0); a mutant that admits any `_unc` slot turns this file red',
        'define internal void @__cq_q_g_1_unc(i32 %out, i32 %k) {\n'
        '  %h_op = call i32 @cq_template_mul_i32_hl(i32 %k, i32 5)\n'
        '  call void @cq_template_mul_i32_hl_unc(i32 %k, i32 %h_op, i32 5)',
        '',
        'call void @cq_template_mul_i32_hl_unc(i32 %k, i32 %h_op, i32 5)'),
    'alias': (
        'an ALIAS: `%k2 = or i32 %k, 0` and then `cqrt_x(%k2)` — the write lands on a '
        'value that is not `%k` by SSA identity',
        'a NON-CALL user of the formal refuses the whole call; a mutant that skips '
        'non-call users (and so never sees `%k2`) turns this file red',
        'define internal void @__cq_q_g_1_unc(i32 %out, i32 %k) {\n'
        '  %k2 = or i32 %k, 0\n'
        '  call void @cqrt_x(i32 %k2)\n'
        '  %h_op = call i32 @cq_template_mul_i32_hl(i32 %k, i32 5)',
        '',
        '%k2 = or i32 %k, 0'),
}
for tag, (what, why, head, decl, pin) in V.items():
    b = body.replace(OLD, head, 1)
    if decl:
        b = b.replace('declare void @cqrt_x(i32)\n', 'declare void @cqrt_x(i32)\n' + decl, 1)
    hdr = (f'; spec_leak_clone_read_twin_{tag}.ll — LEAK + WARNING, deliberately (bd\n'
           '; test_C_libtooling-rhk5). A member of the HOSTILE-TWIN family; its first member,\n'
           '; spec_leak_clone_read_twin_writes_arg.ll, carries the full argument. The module\n'
           '; PRE-SUPPLIES the inner twin `@__cq_q_g_1_unc`, which `Specialization::ensureTwin`\n'
           '; reuses verbatim and `buildClone` records, and this twin WRITES its borrowed\n'
           f'; argument `%k` through {what}.\n'
           '; So the outer call `__cq_q_h_10(0, q)` does NOT leave `q`\'s label alone,\n'
           '; `cloneCallPreservesArg` must refuse it, the caller\'s chain `3q`, `3q ^ q` leaks\n'
           '; and the lyyf-(B) warning stands — the ORACLE\'s disposition (main 9a230646).\n'
           f'; Pinned separately because {why}.\n'
           ';\n'
           '; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err\n'
           '; RUN: %filecheck %s --check-prefix=WARN < %t.err\n'
           '; RUN: %filecheck %s --check-prefix=LEAK < %t.cqd0.ll\n\n')
    chk = ('\n; WARN: warning: {{.*}}cq rotation lowering: non-diagonal gate over a live derived record\n'
           ';\n'
           '; LEAK-LABEL: define i32 @slice(\n'
           '; LEAK: %s = call i32 @__cq_q_h_10(i32 0, i32 %h)\n'
           '; LEAK: call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h_op1, i32 10)\n'
           '; LEAK-NOT: call void @cq_template_xor_i32_unc(\n'
           '; LEAK-NOT: call void @cq_template_mul_i32_hl_unc(i32 %h_op, i32 %h, i32 3)\n'
           '; LEAK: call void @cqrt_ry_i32(i32 %h, double 0x3FE6666666666666)\n'
           '; LEAK-LABEL: define internal void @__cq_q_g_1_unc(i32 %out, i32 %k)\n'
           f'; LEAK: {pin}\n')
    with open(T + f'spec_leak_clone_read_twin_{tag}.ll', 'w') as f:
        f.write(hdr + b + chk)
    print('wrote', f'spec_leak_clone_read_twin_{tag}.ll')
