; control_phase_kickback_reject_rail_chained_between.ll — DECLINE (bd 3qlq.4):
; the branch reads the STALE name. `%b` is rotated in place by `%c = cq_theta(%b,
; …)` BEFORE the branch, so at the branch the rail carries `%c`'s basis while the
; source asked for `%b`'s. `railCondWireDisposition` finds the chained Ry on the
; wire and the DT prong cannot prove it post-branch (it is before it), so the
; region declines with the same string a stale COMPARE gets. Contrast
; `..._rail_chained.ll`, where the branch reads the CURRENT name `%c` and accepts.

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
  %c = call i1 @cq_theta_i1(i1 %b, double 2.500000e-01)
  br i1 %b, label %arm, label %merge
arm:
  call void @cq_phi(double 9.000000e-01)
  br label %merge
merge:
  %m = call i1 @cq_measure_i1(i1 %c)
  ret i1 %m
}

; CHECK: cq controlled lowering: condition predates a non-diagonal gate under quantum control
