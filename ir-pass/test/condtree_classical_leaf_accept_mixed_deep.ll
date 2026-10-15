; condtree_classical_leaf_accept_mixed_deep.ll — ACCEPT (bd test_C_libtooling-xdu2.13).
;
; `and(and(c, t1), t2)`: a mixed node INSIDE a quantum tree. The mixed node is
; the `_hl` template, its parent the ordinary toffoli onto a fresh ancilla, and
; the strip is exact LIFO: the parent's toffoli undo and free while `gl` is still
; allocated, then `gl`'s `_unc` + free, then both compare leaves in reverse mint
; order.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.ll
;
; CHECK-LABEL: define i32 @slice(
; CHECK: %[[V0:[a-z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[V0]], double 2.500000e-01)
; CHECK-NEXT: %c = icmp eq i32 %m, %n
; CHECK-NEXT: %[[V1:[a-z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[V0]], i32 2)
; CHECK-NEXT: %[[V2:[a-z0-9_.]+]] = call i32 @cq_template_and_i1_hl(i32 %[[V1]], i1 zeroext %c)
; CHECK-NEXT: %[[V3:[a-z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[V0]], i32 6)
; CHECK-NEXT: %[[V4:[a-z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[V2]], i32 %[[V3]], i32 %[[V4]])
; CHECK-NEXT: %[[V5:[a-z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[V4]], i32 %[[V5]], i32 10)
; CHECK-NEXT: call void @cqrt_x(i32 %[[V4]])
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[V4]], i32 %[[V5]], i32 7)
; CHECK-NEXT: call void @cqrt_x(i32 %[[V4]])
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[V2]], i32 %[[V3]], i32 %[[V4]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[V4]])
; CHECK-NEXT: call void @cq_template_and_i1_hl_unc(i32 %[[V2]], i32 %[[V1]], i1 zeroext %c)
; CHECK-NEXT: call void @cqrt_free(i32 %[[V2]])
; CHECK-NEXT: call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[V3]], i32 %[[V0]], i32 6)
; CHECK-NEXT: call void @cqrt_free(i32 %[[V3]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[V1]], i32 %[[V0]], i32 2)
; CHECK-NEXT: call void @cqrt_free(i32 %[[V1]])
; CHECK-NEXT: %[[V8:[a-z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[V0]])
; CHECK-NEXT: %[[V9:[a-z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[V5]])
; CHECK-NEXT: %r = add i32 %[[V8]], %[[V9]]
; CHECK-NEXT: ret i32 %r
;
; NEG is a PURE whole-file negative prefix (Rule 12 (a)): the literal is never
; promoted to a qubit, no select survives, and no PredMux mark leaks.
; NEG-NOT: cqrt_alloc_i1(i1 %c)
; NEG-NOT: select i1
; NEG-NOT: cq.predmux

define i32 @slice(i32 %n, i32 %m) {
  %q = call i32 @cq_theta_si32(i32 0, double 2.500000e-01)
  %t1 = icmp sgt i32 %q, 2
  %t2 = icmp slt i32 %q, 6
  %c = icmp eq i32 %m, %n
  %n1 = and i1 %c, %t1
  %n2 = and i1 %n1, %t2
  %s = select i1 %n2, i32 10, i32 7
  %r1 = call i32 @cq_measure_si32(i32 %q)
  %r2 = call i32 @cq_measure_si32(i32 %s)
  %r = add i32 %r1, %r2
  ret i32 %r
}

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
