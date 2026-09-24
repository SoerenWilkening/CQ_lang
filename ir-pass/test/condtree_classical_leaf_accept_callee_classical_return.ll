; condtree_classical_leaf_accept_callee_classical_return.ll — ACCEPT (bd test_C_libtooling-xdu2.13).
;
; The F-1 fence's green twin (reviewer probe q93): `g` is CLASSICAL
; (`k*3 + 1`), and the caller's IR is byte-identical to
; condtree_classical_leaf_reject_callee_quantum_return.ll apart from the callee
; body. The literal `icmp eq %r, %n` is admitted: the fence asks the callee's
; RETURN cone, not "is there a call".
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.ll
;
; CHECK-LABEL: define internal i32 @slice(
; CHECK: %[[V0:[a-z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[V0]], double 5.000000e-01)
; CHECK-NEXT: %r = call i32 @g(i32 %m)
; CHECK-NEXT: %c = icmp eq i32 %r, %n
; CHECK-NEXT: %[[V1:[a-z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[V0]], i32 1)
; CHECK-NEXT: %[[V2:[a-z0-9_.]+]] = call i32 @cq_template_and_i1_hl(i32 %[[V1]], i1 zeroext %c)
; CHECK-NEXT: %[[V3:[a-z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: %[[V4:[a-z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 10)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[V2]], i32 %[[V4]], i32 %[[V3]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[V2]])
; CHECK-NEXT: %[[V5:[a-z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 7)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[V2]], i32 %[[V5]], i32 %[[V3]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[V2]])
; CHECK-NEXT: call void @cq_template_and_i1_hl_unc(i32 %[[V2]], i32 %[[V1]], i1 zeroext %c)
; CHECK-NEXT: call void @cqrt_free(i32 %[[V2]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[V1]], i32 %[[V0]], i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 %[[V1]])
; CHECK-NEXT: %[[V6:[a-z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[V3]])
; CHECK-NEXT: ret i32 %[[V6]]
;
; NEG-NOT: select i1
; NEG-NOT: cq.predmux

define i32 @g(i32 %k) noinline {
  %a = mul i32 %k, 3
  %b = add i32 %a, 1
  ret i32 %b
}
define internal i32 @slice(i32 %m, i32 %n) {
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %r = call i32 @g(i32 %m)
  %t = icmp sgt i32 %q, 1
  %c = icmp eq i32 %r, %n
  %a = and i1 %t, %c
  %s = select i1 %a, i32 10, i32 7
  %m1 = call i32 @cq_measure_si32(i32 %s)
  ret i32 %m1
}

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
