; control_swap_reject_select_rail_measured_parent_name.ll — DECLINE (bd
; test_C_libtooling-r9e5, Rule-13 round-1 item F-B1R1-1, plain-C reachable —
; `bool b0 = 0; b0 = cq_theta(b0, .5); bool b = cq_theta(b0, .3); int m =
; cq_measure(b0); int a = b ? 2 : 5;`): the select's condition `b` is a CHAINED
; theta, so `b` and `b0` are ONE physical register after `lowerRotations`, and
; the measurement names the PARENT. The first B.1 build asked rung (ii) of the
; rail ladder over `b`'s SSA users only and ACCEPTED (exit 0, 2b clean), emitting
; `cqrt_measure_i1(h0)` immediately followed by the merge's `cqrt_cnot(h0, …)` —
; a control read of a collapsed register. Rung (ii) now asks the WIRE
; (`railWireNamesBackward`), the same closure rung (iii) walks.
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
  %b = call i1 @cq_theta_i1(i1 %b0, double 3.000000e-01)
  %mm = call i1 @cq_measure_i1(i1 %b0)
  %s = select i1 %b, i32 2, i32 5
  %m = call i32 @cq_measure_si32(i32 %s)
  %z = zext i1 %mm to i32
  %r = add i32 %m, %z
  ret i32 %r
}

; CHECK: cq controlled lowering: condition measured before the control route under quantum control
