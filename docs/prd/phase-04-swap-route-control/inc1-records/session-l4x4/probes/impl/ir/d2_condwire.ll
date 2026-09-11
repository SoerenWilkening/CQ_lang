declare i1 @cq_theta_i1(i1, double)
declare i32 @cq_theta_si32(i32, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u1, double 2.000000e-01)
  %t = trunc i32 %q to i1
  %c = call i1 @cq_theta_i1(i1 %t, double 5.000000e-01)
  br i1 %c, label %arm, label %merge
arm:
  %ct = call i1 @cq_theta_i1(i1 %c, double 9.000000e-01)
  br label %merge
merge:
  %cm = phi i1 [ %ct, %arm ], [ %c, %entry ]
  %mc = call i1 @cq_measure_i1(i1 %cm)
  %zc = zext i1 %mc to i32
  ret i32 %zc
}
