define i32 @example(i1 %u0, i32 %u1) {
entry:
  %b = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  %q = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  br i1 %b, label %arm, label %merge
arm:
  %q2 = add i32 %q, 7
  br label %merge
merge:
  %m = phi i32 [ %q2, %arm ], [ %q, %entry ]
  %n = call i32 @cq_measure_si32(i32 %m)
  ret i32 %n
}
