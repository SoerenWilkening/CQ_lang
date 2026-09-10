define i32 @example(i1 %u0) {
entry:
  %b = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  %b2 = call i1 @cq_theta_i1(i1 %b, double 2.000000e-01)
  %t = xor i1 %b, %b2
  br i1 %t, label %arm, label %merge
arm:
  call void @cq_phi(double 9.000000e-01)
  br label %merge
merge:
  %m = call i1 @cq_measure_i1(i1 %b2)
  %z = zext i1 %m to i32
  ret i32 %z
}
