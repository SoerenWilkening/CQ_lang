declare ptr @cq_theta_si32(ptr, double)
declare ptr @cq_measure_si32(ptr)
define ptr @example() {
  %q = call ptr @cq_theta_si32(ptr undef, double 5.000000e-01)
  %m = call ptr @cq_measure_si32(ptr %q)
  ret ptr %m
}
