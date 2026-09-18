; A rail-conditioned region whose ARM does real tainted arithmetic on q.
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @probe(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %b = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  br i1 %b, label %arm, label %merge
arm:
  %t1 = add i32 %q, 7
  %t2 = mul i32 %t1, 3
  br label %merge
merge:
  %p  = phi i32 [ %t2, %arm ], [ %q, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %p)
  %mb = call i1 @cq_measure_i1(i1 %b)
  %z  = zext i1 %mb to i32
  %s  = add i32 %m, %z
  ret i32 %s
}
