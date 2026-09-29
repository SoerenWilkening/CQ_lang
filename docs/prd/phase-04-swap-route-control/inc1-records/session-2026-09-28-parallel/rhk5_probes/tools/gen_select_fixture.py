#!/usr/bin/env python3
"""gen_select_fixture.py — derive spec_accept_clone_read_in_discharge_window_select.ll
(family member f07) from the d4 fixture's body."""
W = '/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a7712272d6ca568e9'
T = W + '/ir-pass/test/'
base = open(T + 'spec_accept_clone_read_in_discharge_window.ll').read()
body = ''.join(l + '\n' for l in base.splitlines() if not l.startswith(';')).strip('\n') + '\n'
old = '  %r = add nsw i32 %k, 1\n'
assert body.count(old) == 1
body = body.replace(old, '  %c = icmp sgt i32 %k, 3\n  %r = select i1 %c, i32 %k, i32 0\n')
hdr = """; spec_accept_clone_read_in_discharge_window_select.ll — ACCEPT, DISCHARGED (bd
; test_C_libtooling-rhk5; family member `f07`). The callee `h(a, k) = k > 3 ? k : 0`
; lifts to a clone whose body is the 5po2 clone-select merge: a compare flag, two
; `cqrt_copy_i32_controlled(%h_cmp, %k, %cqq.sel)` (forward + its self-inverse
; replay), the copy-out, and the compare's adjoint. The formal `%k` is a compare
; operand (B1), a controlled copy's SOURCE (B3') and an adjoint read slot (B2) — never
; a destination — so `cloneCallPreservesArg` admits the call and the caller's chain
; `3q`, `3q ^ q` is discharged before the second Ry.
;
; ORACLE (main 9a230646): the lyyf-(B) warning, the chain left allocated. The
; hand-inlined twin (`s = q > 3 ? q : 0`) DECLINES at the 4.4 select's condition-wire
; fence (`condition predates a non-diagonal gate`), so there is no twin stream to
; compare with; this file pins the discharge and the unchanged clone body, and the
; family battery records the member's 2b/entangle.py result (TRACK_RHK5.md §5.2).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=SILENT --allow-empty < %t.err
; RUN: %filecheck %s --check-prefix=LOWER < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CLONE < %t.cqd0.ll

"""
chk = """
; SILENT-NOT: warning
; SILENT-NOT: error
;
; LOWER-LABEL: define i32 @slice(
; LOWER: %s = call i32 @__cq_q_h_10(i32 0, i32 %h)
; LOWER-NEXT: %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op1, i32 10)
; LOWER-NEXT: call void @cqrt_rz_i1(i32 %h_cmp, double 3.141590e+00), !cq.branchphase
; LOWER-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h_op1, i32 10)
; LOWER-NEXT: call void @cq_template_xor_i32_unc(i32 %h_op1, i32 %h, i32 %h_op)
; LOWER-NEXT: call void @cqrt_free(i32 %h_op1)
; LOWER-NEXT: call void @cq_template_mul_i32_hl_unc(i32 %h_op, i32 %h, i32 3)
; LOWER-NEXT: call void @cqrt_free(i32 %h_op)
; LOWER-NEXT: call void @cqrt_free(i32 %h_cmp)
; LOWER-NEXT: %m2 = call i32 @cqrt_measure_i32(i32 %s)
; LOWER-NEXT: call void @cqrt_ry_i32(i32 %h, double 0x3FE6666666666666)
;
; CLONE-LABEL: define internal i32 @__cq_q_h_10(i32 %a, i32 %k)
; CLONE-NEXT: %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %k, i32 3)
; CLONE-NEXT: %cqq.sel = call i32 @cqrt_alloc_i32(i32 0)
; CLONE-NEXT: call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %k, i32 %cqq.sel)
; CLONE-NEXT: %cqq.out = call i32 @cqrt_alloc_i32(i32 0)
; CLONE-NEXT: call void @cqrt_copy_i32(i32 %cqq.sel, i32 %cqq.out)
; CLONE-NEXT: call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %k, i32 %cqq.sel)
; CLONE-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp, i32 %k, i32 3)
; CLONE-NEXT: call void @cqrt_free(i32 %h_cmp)
; CLONE-NEXT: call void @cqrt_free(i32 %cqq.sel)
; CLONE-NEXT: ret i32 %cqq.out
"""
open(T + 'spec_accept_clone_read_in_discharge_window_select.ll', 'w').write(hdr + body + chk)
print('wrote spec_accept_clone_read_in_discharge_window_select.ll')
