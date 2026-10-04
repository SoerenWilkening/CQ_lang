; control_swap_reject_select_rail_measured_parent_before_chain.ll — DECLINE (bd
; test_C_libtooling-r9e5, round-1 item F-B1R1-1's second spelling, plain-C
; reachable — `cq_theta(&b0,.5); int m = cq_measure(b0); bool b = b0;
; cq_theta(&b,.3); int a = b ? 2 : 5;`): the parent name is measured BEFORE the
; chained rotation that defines the condition, so the chain itself is a
; post-measure gate (bd `3d8q`'s stale-reader class, PRE-EXISTING) and the
; select then rides the collapsed register. The first B.1 build accepted it;
; rung (ii) over the wire refuses it — on the measurement, which precedes the
; select's read point through the same wire name.
;
; ⚠ A `DS_Error` decline writes 0 bytes to stdout, so every IR-text negative a
; decline fixture could carry is VACUOUS; what pins "no silent lowering" here is
; the `not` inversion on the RUN line (exit non-zero) plus the string.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_measure_si32(i32)

define i32 @main() {
entry:
  %b0 = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %mm = call i1 @cq_measure_i1(i1 %b0)
  %b = call i1 @cq_theta_i1(i1 %b0, double 3.000000e-01)
  %s = select i1 %b, i32 2, i32 5
  %m = call i32 @cq_measure_si32(i32 %s)
  %z = zext i1 %mm to i32
  %r = add i32 %m, %z
  ret i32 %r
}

; CHECK: cq controlled lowering: condition measured before the control route under quantum control
