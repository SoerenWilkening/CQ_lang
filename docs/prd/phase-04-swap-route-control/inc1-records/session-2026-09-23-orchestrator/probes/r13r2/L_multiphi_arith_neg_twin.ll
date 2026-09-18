declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @probe(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %b = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %t1 = add i32 %q, 7
  %t2 = mul i32 %q, 3
  %p1 = select i1 %b, i32 %q, i32 %t1
  %p2 = select i1 %b, i32 9, i32 %t2
  %m1 = call i32 @cq_measure_si32(i32 %p1)
  %m2 = call i32 @cq_measure_si32(i32 %p2)
  %mb = call i1 @cq_measure_i1(i1 %b)
  %z  = zext i1 %mb to i32
  %s  = add i32 %m1, %m2
  %s2 = add i32 %s, %z
  ret i32 %s2
}
