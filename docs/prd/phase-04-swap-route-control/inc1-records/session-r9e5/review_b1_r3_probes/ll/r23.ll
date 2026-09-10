; r23 — the same with the `xor` AFTER the select (the in-place conversion, if it
; fires, lands after the control read — correct order either way).
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
define i32 @example(i1 %u0) {
entry:
  %b = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  %a = select i1 %b, i32 2, i32 5
  %x = xor i1 %b, true
  %c = call i1 @cq_theta_i1(i1 %x, double 9.000000e-01)
  %m = call i32 @cq_measure_si32(i32 %a)
  %mc = call i1 @cq_measure_i1(i1 %c)
  %z = zext i1 %mc to i32
  %t = add i32 %m, %z
  ret i32 %t
}
