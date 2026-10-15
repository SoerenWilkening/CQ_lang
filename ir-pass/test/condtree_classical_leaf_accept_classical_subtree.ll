; condtree_classical_leaf_accept_classical_subtree.ll — ACCEPT (bd test_C_libtooling-xdu2.13).
;
; `if (q > 2 && m == n && n > 3)`: clang -O1 builds `and(and(c2, c1), t)`. The
; WHOLE classical subtree `%cc` is ONE literal (an untainted child is recorded,
; never walked into), so `%c1`/`%c2`/`%cc` stay ordinary classical code and the
; network holds exactly one mixed node. matrix CASE 5.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.ll
;
; CHECK-LABEL: define i32 @slice(
; CHECK: %[[V0:[a-z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[V0]], double 2.500000e-01)
; CHECK-NEXT: %c1 = icmp eq i32 %m, %n
; CHECK-NEXT: %c2 = icmp sgt i32 %n, 3
; CHECK-NEXT: %cc = and i1 %c2, %c1
; CHECK-NEXT: %[[V1:[a-z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[V0]], i32 2)
; CHECK-NEXT: %[[V2:[a-z0-9_.]+]] = call i32 @cq_template_and_i1_hl(i32 %[[V1]], i1 zeroext %cc)
; CHECK-NEXT: %[[V3:[a-z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[V2]], i32 %[[V3]], i32 10)
; CHECK-NEXT: call void @cqrt_x(i32 %[[V2]])
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[V2]], i32 %[[V3]], i32 7)
; CHECK-NEXT: call void @cqrt_x(i32 %[[V2]])
; CHECK-NEXT: call void @cq_template_and_i1_hl_unc(i32 %[[V2]], i32 %[[V1]], i1 zeroext %cc)
; CHECK-NEXT: call void @cqrt_free(i32 %[[V2]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[V1]], i32 %[[V0]], i32 2)
; CHECK-NEXT: call void @cqrt_free(i32 %[[V1]])
; CHECK-NEXT: %[[V6:[a-z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[V0]])
; CHECK-NEXT: %[[V7:[a-z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[V3]])
; CHECK-NEXT: %r = add i32 %[[V6]], %[[V7]]
; CHECK-NEXT: ret i32 %r
;
; NEG is a PURE whole-file negative prefix (Rule 12 (a)): the literal is never
; promoted to a qubit, no select survives, and no PredMux mark leaks.
; NEG-NOT: cqrt_alloc_i1(i1 %cc)
; NEG-NOT: select i1
; NEG-NOT: cq.predmux

define i32 @slice(i32 %n, i32 %m) {
  %q = call i32 @cq_theta_si32(i32 0, double 2.500000e-01)
  %t = icmp sgt i32 %q, 2
  %c1 = icmp eq i32 %m, %n
  %c2 = icmp sgt i32 %n, 3
  %cc = and i1 %c2, %c1
  %a = and i1 %cc, %t
  %s = select i1 %a, i32 10, i32 7
  %r1 = call i32 @cq_measure_si32(i32 %q)
  %r2 = call i32 @cq_measure_si32(i32 %s)
  %r = add i32 %r1, %r2
  ret i32 %r
}

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
