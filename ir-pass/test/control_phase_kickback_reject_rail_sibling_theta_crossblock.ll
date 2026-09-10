; control_phase_kickback_reject_rail_sibling_theta_crossblock.ll — DECLINE (bd
; 3qlq.4, F-1b-1's CROSS-BLOCK half, rail-only): the sibling in-place Ry on the
; template parent sits in a classically-guarded MIDDLE block and the branch in a
; third. `railCondWireDisposition` has no same-block prong, so before F-1b-1 the
; phase was applied to a register whose state at the branch depended on a
; classical guard the region never saw (a compare cannot reach this shape — it
; declines on `Cond->getParent() != R.Pred`). With the walker crossing the tainted
; arg-0 edge the sibling is on the wire and not provably post-branch.

; ⚠ A `DS_Error` decline writes 0 bytes to stdout, so every IR-text negative a
; decline fixture could carry is VACUOUS; what pins "no silent lowering" here is
; the `not` inversion on the RUN line (exit non-zero) plus the string.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u1, i32 %g) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %t = trunc i32 %q to i1
  %b = call i1 @cq_theta_i1(i1 %t, double 5.000000e-01)
  %cg = icmp ne i32 %g, 0
  br i1 %cg, label %mid, label %pred
mid:
  %c = call i1 @cq_theta_i1(i1 %t, double 9.000000e-01)
  br label %pred
pred:
  br i1 %b, label %arm, label %merge
arm:
  call void @cq_phi(double 7.000000e-01)
  br label %merge
merge:
  %m = call i1 @cq_measure_i1(i1 %b)
  %z = zext i1 %m to i32
  ret i32 %z
}

; CHECK: cq controlled lowering: condition predates a non-diagonal gate under quantum control
