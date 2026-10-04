; control_swap_reject_select_rail_measured_template_parent.ll — DECLINE (bd
; test_C_libtooling-r9e5, round-1 item F-B1R1-1, the NON-theta parent — plain C:
; `int q = 3; cq_theta(&q,.2); bool t = (bool)(q & 1); bool b = t; cq_theta(&b,.5); int m
; = cq_measure(t); int a = b ? 2 : 5;`): `t` is a template (cast) rail and `b`
; is rotated IN PLACE on it, so `t` is a name of the condition's wire; measuring
; it before the select collapses the register the merge controls on.
; `railWireNamesBackward` COLLECTS the non-theta parent and does not enter its
; operands — the twin that measures `q` instead (a DIFFERENT rail, the cast's
; source) is the accept `control_swap_select_rail_other_register_measured.ll`.
;
; ⚠ A `DS_Error` decline writes 0 bytes to stdout, so every IR-text negative a
; decline fixture could carry is VACUOUS; what pins "no silent lowering" here is
; the `not` inversion on the RUN line (exit non-zero) plus the string.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare i32 @cq_theta_si32(i32, double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_measure_si32(i32)

define i32 @main() {
entry:
  %q = call i32 @cq_theta_si32(i32 3, double 2.000000e-01)
  %t = trunc i32 %q to i1
  %b = call i1 @cq_theta_i1(i1 %t, double 5.000000e-01)
  %mt = call i1 @cq_measure_i1(i1 %t)
  %s = select i1 %b, i32 2, i32 5
  %m = call i32 @cq_measure_si32(i32 %s)
  %z = zext i1 %mt to i32
  %r = add i32 %m, %z
  ret i32 %r
}

; CHECK: cq controlled lowering: condition measured before the control route under quantum control
