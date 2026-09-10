define i32 @example(i1 %u0, i32 %g) {
entry:
  %b = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  br i1 %b, label %arm, label %merge
arm:
  call void @cq_phi(double 7.000000e-01)
  br label %merge
merge:
  %p = phi i32 [ 1, %arm ], [ 2, %entry ]
  %m = call i1 @cq_measure_i1(i1 %b)
  %z = zext i1 %m to i32
  %r = add i32 %z, %p
  ret i32 %r
}
