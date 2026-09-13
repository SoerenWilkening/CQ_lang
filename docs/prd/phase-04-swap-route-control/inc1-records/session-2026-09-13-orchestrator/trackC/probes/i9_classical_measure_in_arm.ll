declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_measure_si32(i32)
define i32 @example() {
entry:
  %q = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  br i1 %q, label %arm, label %merge
arm:
  %mc = call i32 @cq_measure_si32(i32 3)
  br label %merge
merge:
  %y = phi i32 [ %mc, %arm ], [ 5, %entry ]
  %mq = call i1 @cq_measure_i1(i1 %q)
  %z = zext i1 %mq to i32
  %r = add nsw i32 %y, %z
  ret i32 %r
}
