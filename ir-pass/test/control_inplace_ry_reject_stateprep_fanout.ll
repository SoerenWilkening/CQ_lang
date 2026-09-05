; control_inplace_ry_reject_stateprep_fanout.ll — DECLINE (R1): the state-prep
; theta has a SECOND consumer (a second merge φ reads it).
;
; Rule 8 linearity. The emitter RAUWs the merge φ to the hoisted theta and
; `lowerRotations` then RAUWs that to the alloc handle; a second consumer reading
; the theta on the ARM edge only would be left naming a rail on a path where the
; controlled gate did not fire — and the whole-DAG spine's chain walk bails on
; fan-out precisely because a shared prefix would be double-uncomputed.
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

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp eq i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 0, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ 0, %entry ]
  %rp = phi i32 [ %rt, %arm ], [ 3, %entry ]
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %mp = call i32 @cq_measure_si32(i32 %rp)
  %s1 = add i32 %mq, %mr
  %s2 = add i32 %s1, %mp
  ret i32 %s2
}
