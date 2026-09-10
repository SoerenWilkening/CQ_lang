define i32 @example(i1 %u0) {
entry:
  %b = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  br i1 %b, label %t, label %f
t:
  call void @cq_phi(double 9.000000e-01)
  call void @cq_phi(double 4.000000e-01)
  br label %merge
f:
  call void @cq_phi(double 3.000000e-01)
  br label %merge
merge:
  %m = call i1 @cq_measure_i1(i1 %b)
  %z = zext i1 %m to i32
  ret i32 %z
}
