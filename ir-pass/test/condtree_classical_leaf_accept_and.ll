; condtree_classical_leaf_accept_and.ll — ACCEPT (bd test_C_libtooling-xdu2.13).
;
; `int a = 7; if (q && m == n) a += 3;` at clang -O1 is a 4.4 DATA select over
; `and i1 (icmp eq m, n), (icmp ne q, 0)` — one CLASSICAL leaf, one tainted
; (tests/e2e/condtree_classical_leaf_matrix.c CASE 1). The classical leaf is the
; LITERAL of the existing `cq_template_and_i1_hl` (the §5.2 mixed-operand
; convention; never a qubit), the tainted leaf mints its flag as always, and the
; select's controlled copies run on the node's rail:
;   h_cmp = icmp_ne_hl(h, 0); gl = and_i1_hl(h_cmp, c); copy/x/copy/x on gl;
;   and_i1_hl_unc(gl, h_cmp, c) — the SAME SSA literal; free(gl); the compare
;   strip; free(h_cmp).
; `gl ^= h_cmp ∧ c` twice is 0 on every basis branch (c is one classical bit),
; so `cqrt_free(gl)` is a proven-|0> free (Rule 6).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.ll
; RUN: %filecheck %s --check-prefix=CNT < %t.ll
; RUN: %filecheck %s --check-prefix=CNT2 < %t.ll
;
; CHECK-LABEL: define i32 @slice(
; CHECK:      %[[H:[a-z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 2.500000e-01)
; CHECK-NEXT: %c = icmp eq i32 %m, %n
; CHECK-NEXT: %[[F:h_cmp[0-9]*]] = call i32 @cq_template_icmp_ne_i32_hl(i32 %[[H]], i32 0)
; CHECK-NEXT: %[[G:gl[0-9]*]] = call i32 @cq_template_and_i1_hl(i32 %[[F]], i1 %c)
; CHECK-NEXT: %[[OUT:out[0-9]*]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: %[[T:selop[0-9]*]] = call i32 @cqrt_alloc_i32(i32 10)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[G]], i32 %[[T]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[G]])
; CHECK-NEXT: %[[E:selop[0-9]*]] = call i32 @cqrt_alloc_i32(i32 7)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[G]], i32 %[[E]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[G]])
; CHECK-NEXT: call void @cq_template_and_i1_hl_unc(i32 %[[G]], i32 %[[F]], i1 %c)
; CHECK-NEXT: call void @cqrt_free(i32 %[[G]])
; CHECK-NEXT: call void @cq_template_icmp_ne_i32_hl_unc(i32 %[[F]], i32 %[[H]], i32 0)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: %{{[a-z0-9_.]+}} = call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NEXT: %{{[a-z0-9_.]+}} = call i32 @cqrt_measure_i32(i32 %[[OUT]])
;
; Whole-file negatives in a PURE prefix, counts in their own (Rule 12 (a)):
; the literal is never promoted, never a toffoli control, the select is gone,
; and no PredMux mark leaks into the output.
; NEG-NOT: cqrt_alloc_i1(i1 %c)
; NEG-NOT: cqrt_toffoli
; NEG-NOT: select i1
; NEG-NOT: cq.predmux
; CNT: call i32 @cq_template_and_i1_hl(
; CNT-NOT: call i32 @cq_template_and_i1_hl(
; CNT2: call void @cq_template_and_i1_hl_unc(
; CNT2-NOT: call void @cq_template_and_i1_hl_unc(

define i32 @slice(i32 %n, i32 %m) {
  %q = call i32 @cq_theta_si32(i32 0, double 2.500000e-01)
  %t = icmp ne i32 %q, 0
  %c = icmp eq i32 %m, %n
  %a = and i1 %c, %t
  %s = select i1 %a, i32 10, i32 7
  %r1 = call i32 @cq_measure_si32(i32 %q)
  %r2 = call i32 @cq_measure_si32(i32 %s)
  %r = add i32 %r1, %r2
  ret i32 %r
}

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
