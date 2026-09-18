declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @probe(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %b = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %c = icmp sgt i32 %q, 1
  %t = xor i1 %b, %c
  br i1 %t, label %arm, label %merge
arm:
  br label %merge
merge:
  %p1 = phi i32 [ 2, %arm ], [ 5, %entry ]
  %p2 = phi i32 [ 3, %arm ], [ 6, %entry ]
  %m1 = call i32 @cq_measure_si32(i32 %p1)
  %m2 = call i32 @cq_measure_si32(i32 %p2)
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mb = call i1 @cq_measure_i1(i1 %b)
  %z  = zext i1 %mb to i32
  %s  = add i32 %m1, %m2
  %s2 = add i32 %s, %mq
  %s3 = add i32 %s2, %z
  ret i32 %s3
}
