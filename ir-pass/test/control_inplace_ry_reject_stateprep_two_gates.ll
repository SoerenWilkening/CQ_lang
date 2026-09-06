; control_inplace_ry_reject_stateprep_two_gates.ll — DECLINE (R1): TWO thetas in
; one arm — a state prep chained into a second rotation.
;
; The emitter hoists exactly ONE gate per arm (`R.Shadow.assign(1, T)`), so a
; second gate in the block would be dropped by the flatten. Note this is NOT a
; statement that the shape is unlowerable — `alloc(0); cRy(f,.4); cRy(f,.9)`
; would be a correct circuit — only that Inc 4 does not build it and refuses
; rather than emitting half a region (Rule 1).
; R1's OTHER THREE HALVES ARE UNCHANGED BY INC 4 AND STILL REQUIRED. Only the
; arg-0 half moved: `inPlaceRotationArmTheta` now reports a classical seed as
; STATE PREP instead of returning null. "Defined in `ArmBB`", "sole user is the
; merge φ" and "nothing else in the block" are asked ONCE, of BOTH arm classes,
; through the same code — which is why these fixtures are the state-prep
; spellings of the pre-existing `control_inplace_ry_reject_{stray_op,two_thetas,
; theta_phi_arm}.ll` and must keep the same string.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled
; 3qlq: migrated from register cq_phi (dead declare erased)

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp eq i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %r1 = call i32 @cq_theta_si32(i32 0, double 4.000000e-01)
  %rt = call i32 @cq_theta_si32(i32 %r1, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ 0, %entry ]
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %s  = add i32 %mq, %mr
  ret i32 %s
}
