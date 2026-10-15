; condtree_classical_leaf_accept_measured_literal.ll — ACCEPT (bd test_C_libtooling-xdu2.13).
;
; A `cq_measure` result is CLASSICAL (the sink, Rule 3) even though its argument
; is a register, so `icmp eq %mr, %n` stays a legal `_hl` literal. (It pinned the
; argument-skip of round 2's conjunct (d), now removed; it stays as the green
; boundary of bd 3jru — a measure is not a call to a defined function.)
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.ll
;
; CHECK-LABEL: define i32 @slice(
; CHECK: %[[V0:[a-z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %m)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[V0]], double 0x3FE6666666666666)
; CHECK-NEXT: %[[V1:[a-z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[V0]])
; CHECK-NEXT: %[[V2:[a-z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[V2]], double 5.000000e-01)
; CHECK-NEXT: %c = icmp eq i32 %[[V1]], %n
; CHECK-NEXT: %[[V3:[a-z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[V2]], i32 1)
; CHECK-NEXT: %[[V4:[a-z0-9_.]+]] = call i32 @cq_template_and_i1_hl(i32 %[[V3]], i1 zeroext %c)
; CHECK-NEXT: %[[V5:[a-z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[V4]], i32 %[[V5]], i32 10)
; CHECK-NEXT: call void @cqrt_x(i32 %[[V4]])
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[V4]], i32 %[[V5]], i32 7)
; CHECK-NEXT: call void @cqrt_x(i32 %[[V4]])
; CHECK-NEXT: call void @cq_template_and_i1_hl_unc(i32 %[[V4]], i32 %[[V3]], i1 zeroext %c)
; CHECK-NEXT: call void @cqrt_free(i32 %[[V4]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[V3]], i32 %[[V2]], i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 %[[V3]])
; CHECK-NEXT: %[[V8:[a-z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[V5]])
; CHECK-NEXT: ret i32 %[[V8]]
;
; NEG-NOT: select i1
; NEG-NOT: cq.predmux

define i32 @slice(i32 %m, i32 %n) {
  %r = call i32 @cq_theta_si32(i32 %m, double 7.000000e-01)
  %mr = call i32 @cq_measure_si32(i32 %r)
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %t = icmp sgt i32 %q, 1
  %c = icmp eq i32 %mr, %n
  %a = and i1 %t, %c
  %s = select i1 %a, i32 10, i32 7
  %m1 = call i32 @cq_measure_si32(i32 %s)
  ret i32 %m1
}

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
