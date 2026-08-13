; control_swap_diamond_derived_polarity.ll — ACCEPT: derived base × FALSE-successor arm.
;
; The Rule-9 polarity case (clang -O1 canonicalizes `if (u != k)` to
; `icmp eq; br eq, Merge, Arm`, swapping successors) COMPOSED with the derived
; base (test_C_libtooling-9hh): the gate arm is the FALSE successor and both its
; spine base and the merge straight-through are the pre-region %qd. Must lower
; to the IDENTICAL routed stream as control_swap_diamond_derived.ll except the
; route cswaps are ¬flag-bracketed (`cqrt_x(flag)` self-inverse pairs), exactly
; like the un-derived control_swap_diamond_polarity.ll. Arms are resolved by
; merge-phi incoming IDENTITY, not edge order.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %qd = call i32 @cq_phi_si32(i32 %q, double 9.000000e-01)
  %c = icmp eq i32 %qd, 5
  br i1 %c, label %merge, label %arm   ; gate arm on the FALSE edge
arm:
  %q1 = call i32 @cq_phi_si32(i32 %qd, double %a)
  br label %merge
merge:
  %qm = phi i32 [ %q1, %arm ], [ %qd, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}

; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK:     call void @cqrt_rz_i32(i32 %[[Q]], double 9.000000e-01)
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 5)
; CHECK:     %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; route-in under ¬flag: self-inverse X bracket
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[Q]], i32 %[[T]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cqrt_rz_i32(i32 %[[T]], double %a)
; route-back under ¬flag
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[Q]], i32 %[[T]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cqrt_free(i32 %[[T]])
; CHECK:     call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK:     call void @cqrt_free(i32 %[[F]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[Q]])
; CHECK-NOT: call void @cqrt_free
; CHECK-NOT: _controlled
; CHECK-NOT: cqrt_copy
; CHECK-NOT: phi i32

; CNT-COUNT-2: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(
