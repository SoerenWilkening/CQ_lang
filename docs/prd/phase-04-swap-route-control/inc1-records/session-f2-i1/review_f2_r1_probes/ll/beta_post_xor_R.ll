declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @slice(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp eq i32 %q, 5
  br i1 %c, label %merge, label %arm
arm:
  %rt = call i32 @cq_theta_si32(i32 5, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %q, %entry ]
  %p  = xor i32 %rm, 3
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mp = call i32 @cq_measure_si32(i32 %p)
  %s  = add i32 %mq, %mp
  ret i32 %s
}
