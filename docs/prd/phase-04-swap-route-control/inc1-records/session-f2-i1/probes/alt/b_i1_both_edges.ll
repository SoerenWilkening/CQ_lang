
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)

define i32 @example(i1 %u0) {
entry:
  %q = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  %c = icmp eq i1 %q, true
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i1 @cq_theta_i1(i1 false, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i1 [ %rt, %arm ], [ %q, %entry ]
  %mq = call i1 @cq_measure_i1(i1 %q)
  %mr = call i1 @cq_measure_i1(i1 %rm)
  ret i32 0
}
