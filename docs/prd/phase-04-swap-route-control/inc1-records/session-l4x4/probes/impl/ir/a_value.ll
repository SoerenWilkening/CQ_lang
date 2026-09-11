declare i1 @cq_theta_i1(i1, double)
declare i32 @cq_theta_si32(i32, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u1) {
entry:
  %c = call i1 @cq_theta_i1(i1 false, double 1.100000e+00)
  %r = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  br i1 %c, label %arm, label %merge
arm:
  %rt = add nsw i32 %r, 3
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %r, %entry ]
  %mc = call i1 @cq_measure_i1(i1 %c)
  %zc = zext i1 %mc to i32
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %s  = add i32 %mr, %zc
  ret i32 %s
}
