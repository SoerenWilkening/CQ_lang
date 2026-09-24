; condtree_classical_leaf_accept_argument_literal.ll — ACCEPT (bd test_C_libtooling-xdu2.13).
;
; The literal is an `i1` function ARGUMENT (not an instruction): admitted by
; `condLiteralAdmissible`'s Argument arm, passed to the `_hl` slot unchanged.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.ll
;
; CHECK-LABEL: define i32 @slice(
; CHECK: %[[V0:[a-z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[V0]], double 2.500000e-01)
; CHECK-NEXT: %[[V1:[a-z0-9_.]+]] = call i32 @cq_template_icmp_ne_i32_hl(i32 %[[V0]], i32 0)
; CHECK-NEXT: %[[V2:[a-z0-9_.]+]] = call i32 @cq_template_and_i1_hl(i32 %[[V1]], i1 zeroext %b)
; CHECK-NEXT: %[[V3:[a-z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: %[[V4:[a-z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 10)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[V2]], i32 %[[V4]], i32 %[[V3]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[V2]])
; CHECK-NEXT: %[[V5:[a-z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 7)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[V2]], i32 %[[V5]], i32 %[[V3]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[V2]])
; CHECK-NEXT: call void @cq_template_and_i1_hl_unc(i32 %[[V2]], i32 %[[V1]], i1 zeroext %b)
; CHECK-NEXT: call void @cqrt_free(i32 %[[V2]])
; CHECK-NEXT: call void @cq_template_icmp_ne_i32_hl_unc(i32 %[[V1]], i32 %[[V0]], i32 0)
; CHECK-NEXT: call void @cqrt_free(i32 %[[V1]])
; CHECK-NEXT: %[[V6:[a-z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[V0]])
; CHECK-NEXT: %[[V7:[a-z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[V3]])
; CHECK-NEXT: %r = add i32 %[[V6]], %[[V7]]
; CHECK-NEXT: ret i32 %r
;
; NEG is a PURE whole-file negative prefix (Rule 12 (a)): the literal is never
; promoted to a qubit, no select survives, and no PredMux mark leaks.
; NEG-NOT: cqrt_alloc_i1(i1 %b)
; NEG-NOT: select i1
; NEG-NOT: cq.predmux

define i32 @slice(i32 %n, i1 %b) {
  %q = call i32 @cq_theta_si32(i32 0, double 2.500000e-01)
  %t = icmp ne i32 %q, 0
  %a = and i1 %b, %t
  %s = select i1 %a, i32 10, i32 7
  %r1 = call i32 @cq_measure_si32(i32 %q)
  %r2 = call i32 @cq_measure_si32(i32 %s)
  %r = add i32 %r1, %r2
  ret i32 %r
}

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
