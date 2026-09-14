declare i128 @cq_theta_si32(i128, double)
declare i128 @cq_measure_si32(i128)
define i128 @example() {
  %q = call i128 @cq_theta_si32(i128 undef, double 5.000000e-01)
  %m = call i128 @cq_measure_si32(i128 %q)
  ret i128 %m
}
