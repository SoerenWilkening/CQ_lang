
declare i32 @cq_theta_si32(i32, double)
declare i1 @cq_theta_i1(i1, double)
declare i32 @cq_measure_si32(i32)
declare i1 @cq_measure_i1(i1)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 3.000000e-01)
  %c = icmp eq i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i1 @cq_theta_i1(i1 %c, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i1 [ %rt, %arm ], [ true, %entry ]
  %mc = call i1 @cq_measure_i1(i1 %c)
  %mr = call i1 @cq_measure_i1(i1 %rm)
  %mq = call i32 @cq_measure_si32(i32 %q)
  ret i32 %mq
}
