; control_phase_kickback_reject_rail_measured_sidepath.ll — DECLINE (bd 3qlq.4,
; Rule-13 round-1 finding F-1b-2): the `_Bool` register is measured on a
; classically-guarded SIDE PATH that neither is `Pred` nor dominates it, then
; branched on. `railMeasuredBeforeBranch` was dominance-based and accepted; it now
; asks REACHABILITY (`isPotentiallyReachable(measure, branch)`): the branch can
; execute after the measurement on that path, so the kickback would be a
; post-measure gate. (No wrong unitary was found — after the measurement the
; register is a basis state and the phase is global either way — but the fence's
; own statement was false, and a fence that does not do what it says is how this
; project's worst defects shipped.) The same-block spelling is
; `..._reject_rail_measured_early.ll`; a measurement AFTER the region accepts.

; ⚠ A `DS_Error` decline writes 0 bytes to stdout, so every IR-text negative a
; decline fixture could carry is VACUOUS; what pins "no silent lowering" here is
; the `not` inversion on the RUN line (exit non-zero) plus the string.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i1 %u0, i32 %g) {
entry:
  %b = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  %cg = icmp ne i32 %g, 0
  br i1 %cg, label %mm, label %pred
mm:
  %m0 = call i1 @cq_measure_i1(i1 %b)
  br label %pred
pred:
  %p = phi i1 [ %m0, %mm ], [ false, %entry ]
  br i1 %b, label %arm, label %merge
arm:
  call void @cq_phi(double 9.000000e-01)
  br label %merge
merge:
  %z = zext i1 %p to i32
  ret i32 %z
}

; CHECK: cq controlled lowering: condition measured before the control route under quantum control
