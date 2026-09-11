declare i1 @cq_theta_i1(i1, double)
declare i32 @cq_theta_si32(i32, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u1, double 2.000000e-01)
  %t = trunc i32 %q to i1
  %c = call i1 @cq_theta_i1(i1 %t, double 5.000000e-01)
  %rb = zext i1 %c to i32
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %rb, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %rb, %entry ]
  %mr = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %mr
}
