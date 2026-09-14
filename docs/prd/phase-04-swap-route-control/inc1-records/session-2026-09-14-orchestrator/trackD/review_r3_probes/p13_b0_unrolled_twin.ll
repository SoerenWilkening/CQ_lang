declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @opaque()
define i32 @example() {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 2.500000e-01)
  %b = call i32 @cq_theta_si32(i32 %q, double 9.000000e-01)
  %m = call i32 @cq_measure_si32(i32 %b)
  %t1 = add nsw i32 %m, 1
  %t2 = add nsw i32 %t1, 1
  ret i32 %t2
}
