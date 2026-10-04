; control_phase_kickback_reject_rail_measured_parent_name.ll — DECLINE (bd
; test_C_libtooling-r9e5, Rule-13 round-1 item F-B1R1-1 — the KICKBACK twin,
; plain-C reachable: `cq_theta(&b0,.5); bool b = b0; cq_theta(&b,.3); int m =
; cq_measure(b0); if (b) cq_phi(.9);`). `railMeasuredBeforeReadPoint` is ONE
; helper with two read points (the branch here, the select in 1b-B.1); until
; F-B1R1-1 it asked the rail's SSA users only, so the measurement of the PARENT
; name `b0` — the same register after `lowerRotations` — was invisible and this
; module ACCEPTED on `main` b00fdc2 (5 trace lines, `measure_i1(h0)` then
; `rz_i1(h0, .9)`: a phase on a collapsed register). Now the measure set is the
; wire (`railWireNamesBackward`), for both callers at once.
;
; ⚠ A `DS_Error` decline writes 0 bytes to stdout, so every IR-text negative a
; decline fixture could carry is VACUOUS; what pins "no silent lowering" here is
; the `not` inversion on the RUN line (exit non-zero) plus the string.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)

define i32 @main() {
entry:
  %b0 = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %b = call i1 @cq_theta_i1(i1 %b0, double 3.000000e-01)
  %mm = call i1 @cq_measure_i1(i1 %b0)
  br i1 %b, label %arm, label %merge
arm:
  call void @cq_phi(double 9.000000e-01)
  br label %merge
merge:
  %z = zext i1 %mm to i32
  ret i32 %z
}

; CHECK: cq controlled lowering: condition measured before the control route under quantum control
