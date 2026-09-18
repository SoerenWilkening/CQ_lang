declare i1 @cq_theta_i1(i1, double) memory(none) nounwind willreturn
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @probe(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %rail = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %dead = and i1 %rail, false
  %z2 = zext i1 %dead to i32
  %m  = call i32 @cq_measure_si32(i32 %q)
  %s2 = add i32 %z2, %m
  ret i32 %s2
}
