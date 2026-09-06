; control_angle_select_reject_runtime_one_arm.ll — DECLINE (S1, the ARM-VALUE
; fence): ONE arm is a `ConstantFP` and the OTHER is a run-time function
; parameter.
;
;     %ang = select i1 %c, double 9.000000e-01, double %y
;
; WHY THIS FILE EXISTS SEPARATELY FROM THE TWO-RUNTIME-ARM ONES. The narrowed
; predicate is "**BOTH** arms are `ConstantFP`", and a fence written as a
; conjunction has two ways to be spelled wrong: `A || B` instead of `A && B` would
; accept this module while still declining the two-parameter one. This is the
; cell that separates them, and it is the shape a partial-evaluation widening
; would reach for first ("one arm is known, surely we can bound the other") —
; which is exactly what cannot be done: the residual is a property of the
; DIFFERENCE, and `fl(0.9 − y)` is as unbounded in absolute radians, and as able
; to be `inf`/`NaN`, as `fl(x − y)` is. Knowing ONE operand bounds nothing.
;
; Note also that the difference is synthesized here too: the emitted stream would
; carry a real `fsub double 9.000000e-01, %y`, an operation the source never
; wrote. That is the clearance's finding F-11 in its cheapest spelling.
;
; The full argument, the five plain-C reproducers, the twin fact and the owner's
; one-line widening option (1) are in
; `control_angle_select_reject_runtime_arms.ll`'s header.
;
; NO NEW DIAGNOSTIC STRING: S1 returns `NotApplicable` and gate 3's pre-existing
; `rotation angle` decline fires.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}rotation angle under quantum control
; 3qlq: migrated from register cq_phi (dead declare erased)

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1, double %y) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %c = icmp eq i32 %q, 5
  %ang = select i1 %c, double 9.000000e-01, double %y
  %t = call i32 @cq_theta_si32(i32 %r, double %ang)
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %t)
  %s = add i32 %mq, %mr
  ret i32 %s
}

; CHECK-NOT: fsub double
; CHECK-NOT: cqrt_ry_i32_controlled
