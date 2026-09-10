; control_angle_select_reject_rail_ry.ll — DECLINE (bd 3qlq.4, follow-on 1b-C):
; the Ry-stem ANGLE SELECT on a bare rail — `if (b) r = cq_theta(r, A); else r =
; cq_theta(r, B);` folded to one theta with a selected angle. By difference this
; would be `ry(h, B)` + `cqrt_ry_<W>_controlled(h_b, h, A−B)` controlled on the
; register; the controlled-Ry family's fences (R4 disjoint wires, the structural
; freeze, S7–S9) were argued for a MINTED flag and are re-argued for a borrowed
; one in 1b-C, not here. Declined (not `NotApplicable`, which the caller reports
; as `rotation angle`, the wrong reason) with `kBareRailCondReason`.

; ⚠ A `DS_Error` decline writes 0 bytes to stdout, so every IR-text negative a
; decline fixture could carry is VACUOUS; what pins "no silent lowering" here is
; the `not` inversion on the RUN line (exit non-zero) plus the string.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i1 %u0, i32 %u1) {
entry:
  %b = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 2.000000e-01)
  %a = select i1 %b, double 9.000000e-01, double 3.000000e-01
  %r2 = call i32 @cq_theta_si32(i32 %r, double %a)
  %n = call i32 @cq_measure_si32(i32 %r2)
  %m = call i1 @cq_measure_i1(i1 %b)
  %z = zext i1 %m to i32
  %s = add i32 %n, %z
  ret i32 %s
}

; CHECK: cq controlled lowering: bare i1 register condition under quantum control
