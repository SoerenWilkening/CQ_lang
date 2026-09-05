; control_inplace_ry_reject_stateprep_theta_phi_arm.ll — DECLINE (R1): a state
; prep followed by a `cq_phi` in the same arm.
;
; The arm incoming is the `cq_phi`, not the theta, so `inPlaceRotationArmTheta`
; never sees a theta at the incoming at all and the region falls through to the
; pre-existing decline. Committed as the state-prep spelling of
; `control_inplace_ry_reject_theta_phi_arm.ll` because the two files differ ONLY
; in the theta's arg-0, which is the operand Inc 4 changed the meaning of.
; R1's OTHER THREE HALVES ARE UNCHANGED BY INC 4 AND STILL REQUIRED. Only the
; arg-0 half moved: `inPlaceRotationArmTheta` now reports a classical seed as
; STATE PREP instead of returning null. "Defined in `ArmBB`", "sole user is the
; merge φ" and "nothing else in the block" are asked ONCE, of BOTH arm classes,
; through the same code — which is why these fixtures are the state-prep
; spellings of the pre-existing `control_inplace_ry_reject_{stray_op,two_thetas,
; theta_phi_arm}.ll` and must keep the same string.
;
;
; 3qlq(prep_a2): the asserted diagnostic was WIDENED to the whole DS_Error
; text on the Inc-1 binary.  The refusing CLAUSE is UNCHANGED — the new
; string ENDS WITH the old one — and this is Rule 12's
; character-for-character mirror rather than a disposition change: a
; suffix-only assertion would still match if some OTHER subsystem grew a
; message with the same tail.
; OLD: control flow under quantum control
; NEW: cq controlled lowering: control flow under quantum control
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: control flow under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp eq i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %r1 = call i32 @cq_theta_si32(i32 0, double 4.000000e-01)
  call void @cq_phi(double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %r1, %arm ], [ 0, %entry ]
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %s  = add i32 %mq, %mr
  ret i32 %s
}
