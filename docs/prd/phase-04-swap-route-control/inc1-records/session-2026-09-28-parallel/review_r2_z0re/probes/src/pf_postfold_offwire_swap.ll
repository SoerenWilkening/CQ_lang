
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %m, i32 %s) {
entry:
  %q = call i32 @cq_theta_si32(i32 %m, double 5.000000e-01)
  %q2 = call i32 @cq_theta_si32(i32 7, double 4.000000e-01)
  %c = icmp sgt i32 %q2, 3
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %s, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %s, %entry ]
  %t = sdiv i32 %q, 4
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %mt = call i32 @cq_measure_si32(i32 %t)
  %a = add nsw i32 %mt, %mr
  %mq2 = call i32 @cq_measure_si32(i32 %q2)
  %b = add nsw i32 %a, %mq2
  ret i32 %b
}


