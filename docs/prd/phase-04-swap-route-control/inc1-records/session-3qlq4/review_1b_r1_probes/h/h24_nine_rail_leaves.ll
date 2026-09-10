define i32 @example(i1 %u0) {
entry:
  %b1 = call i1 @cq_theta_i1(i1 %u0, double 1.000000e-01)
  %b2 = call i1 @cq_theta_i1(i1 %u0, double 2.000000e-01)
  %b3 = call i1 @cq_theta_i1(i1 %u0, double 3.000000e-01)
  %b4 = call i1 @cq_theta_i1(i1 %u0, double 4.000000e-01)
  %b5 = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  %b6 = call i1 @cq_theta_i1(i1 %u0, double 6.000000e-01)
  %b7 = call i1 @cq_theta_i1(i1 %u0, double 7.000000e-01)
  %b8 = call i1 @cq_theta_i1(i1 %u0, double 8.000000e-01)
  %b9 = call i1 @cq_theta_i1(i1 %u0, double 9.000000e-01)
  %a1 = and i1 %b1, %b2
  %a2 = and i1 %a1, %b3
  %a3 = and i1 %a2, %b4
  %a4 = and i1 %a3, %b5
  %a5 = and i1 %a4, %b6
  %a6 = and i1 %a5, %b7
  %a7 = and i1 %a6, %b8
  %a8 = and i1 %a7, %b9
  br i1 %a8, label %arm, label %merge
arm:
  call void @cq_phi(double 7.000000e-01)
  br label %merge
merge:
  %m = call i1 @cq_measure_i1(i1 %b1)
  %z = zext i1 %m to i32
  ret i32 %z
}
