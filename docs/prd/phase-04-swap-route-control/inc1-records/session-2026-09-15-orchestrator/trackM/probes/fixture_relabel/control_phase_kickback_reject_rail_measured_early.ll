; control_phase_kickback_reject_rail_measured_early.ll — DECLINE (bd 3qlq.4):
; the `_Bool` register is MEASURED before the branch that reads it. A measured
; register is classical from there on, and firing the kickback on its rail after
; the measurement would be a post-measure gate — Rule 6's loud-reject class. The
; mirror of the compare path's `MeasuredEarly` (`railMeasuredBeforeBranch`: a
; `cq_measure` user in `Pred`, or in a block that dominates it). A measurement
; DOWNSTREAM of the region is the ordinary case (`..._rail_diamond.ll`).

; ⚠ A `DS_Error` decline writes 0 bytes to stdout, so every IR-text negative a
; decline fixture could carry is VACUOUS; what pins "no silent lowering" here is
; the `not` inversion on the RUN line (exit non-zero) plus the string.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i1 @example(i1 %u0) {
entry:
  %b = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  %m = call i1 @cq_measure_i1(i1 %b)
  br i1 %m, label %arm, label %merge
arm:
  call void @cq_phi(double 9.000000e-01)
  br label %merge
merge:
  ret i1 %m
}

; CHECK: cq controlled lowering: condition measured before the control route under quantum control
