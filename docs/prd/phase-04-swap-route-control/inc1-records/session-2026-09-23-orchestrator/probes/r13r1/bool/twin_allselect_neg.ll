declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @probe(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %rail = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %c = icmp sgt i32 %q, 1
  %nr = xor i1 %rail, true
  %p  = and i1 %nr, %c
  %a4 = select i1 %rail, i32 2, i32 5
  %b5 = select i1 %rail, i32 2, i32 6
  %c6 = select i1 %rail, i32 2, i32 7
  %sel = select i1 %p, i32 %a4, i32 %b5
  %m1 = call i32 @cq_measure_si32(i32 %sel)
  %m2 = call i32 @cq_measure_si32(i32 %c6)
  %mb = call i1 @cq_measure_i1(i1 %rail)
  %z  = zext i1 %mb to i32
  %s  = add i32 %m1, %m2
  %s2 = add i32 %s, %z
  ret i32 %s2
}
