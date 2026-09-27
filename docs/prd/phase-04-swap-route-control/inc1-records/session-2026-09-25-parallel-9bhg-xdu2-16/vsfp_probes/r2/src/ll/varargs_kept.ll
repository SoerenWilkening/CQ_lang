declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @hv(i32 %a, ...) {
  ret i32 7
}

define i32 @main(i32 %m) {
  %q = call i32 @cq_theta_si32(i32 %m, double 5.000000e-01)
  %z = call i32 @cq_measure_si32(i32 %q)
  %t = call i32 (i32, ...) @hv(i32 %m, i32 %z)
  %s = add i32 %t, %z
  ret i32 %s
}
