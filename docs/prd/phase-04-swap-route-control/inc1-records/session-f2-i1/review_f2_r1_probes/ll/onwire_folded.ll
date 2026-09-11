declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %t  = and i32 %q, 0
  %b  = call i32 @cq_theta_si32(i32 %t, double 3.000000e-01)
  %c  = icmp eq i32 %b, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 0, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ 0, %entry ]
  %mb = call i32 @cq_measure_si32(i32 %b)
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %s  = add i32 %mb, %mr
  ret i32 %s
}
