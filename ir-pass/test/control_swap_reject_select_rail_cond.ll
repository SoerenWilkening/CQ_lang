; control_swap_reject_select_rail_cond.ll — DECLINE (bd 3qlq.4, follow-on 1b-B):
; the 4.4 DATA select whose condition is the bare `_Bool` register (`int a = 5;
; if (b) a -= 3;` → `select i1 %b, i32 2, i32 5`). The copy merge would be two
; `cqrt_copy_<W>_controlled` controlled on the register itself, with no mint,
; strip or free — a real lowering, scoped as its own increment with its own
; probe family. Declined AFTER the angle-select hand-off (the Rz-stem angle
; select on a rail DOES lower — `control_angle_select_phase_rail.ll`), with the
; ONE string every not-yet-lowered rail consumer shares (`kBareRailCondReason`).

; ⚠ A `DS_Error` decline writes 0 bytes to stdout, so every IR-text negative a
; decline fixture could carry is VACUOUS; what pins "no silent lowering" here is
; the `not` inversion on the RUN line (exit non-zero) plus the string.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i1 %u0) {
entry:
  %b = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  %a = select i1 %b, i32 2, i32 5
  %n = call i32 @cq_measure_si32(i32 %a)
  %m = call i1 @cq_measure_i1(i1 %b)
  %z = zext i1 %m to i32
  %r = add i32 %n, %z
  ret i32 %r
}

; CHECK: cq controlled lowering: bare i1 register condition under quantum control
