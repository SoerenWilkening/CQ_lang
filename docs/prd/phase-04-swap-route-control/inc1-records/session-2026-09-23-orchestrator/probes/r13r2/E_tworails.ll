; TWO rails: %r1 conditions the region and goes dead (all-false phis); %r2 is
; measured.  Does the dead %r1 still close?
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @probe(i32 %u) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %r1 = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %r2 = call i1 @cq_theta_i1(i1 false, double 7.000000e-01)
  br i1 %r1, label %arm, label %merge
arm:
  br label %merge
merge:
  %p1 = phi i1 [ false, %arm ], [ false, %entry ]
  %z1 = zext i1 %p1 to i32
  %m  = call i32 @cq_measure_si32(i32 %q)
  %mb = call i1 @cq_measure_i1(i1 %r2)
  %z2 = zext i1 %mb to i32
  %s  = add i32 %z1, %m
  %s2 = add i32 %s, %z2
  ret i32 %s2
}
