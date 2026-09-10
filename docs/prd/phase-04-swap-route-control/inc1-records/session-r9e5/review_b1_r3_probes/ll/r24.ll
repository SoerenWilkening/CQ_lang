; r24 — the `xor` BEFORE the select and the chained theta AFTER it: the
; strongest form of r22 (the only later use of `%b` at M-C time is the emitted
; `cqrt_cnot`, and the rotation of the aliased name happens after the read).
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
define i32 @example(i1 %u0) {
entry:
  %b = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  %x = xor i1 %b, true
  %a = select i1 %b, i32 2, i32 5
  %c = call i1 @cq_theta_i1(i1 %x, double 9.000000e-01)
  %m = call i32 @cq_measure_si32(i32 %a)
  %mc = call i1 @cq_measure_i1(i1 %c)
  %z = zext i1 %mc to i32
  %t = add i32 %m, %z
  ret i32 %t
}
