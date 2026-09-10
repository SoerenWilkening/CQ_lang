define i32 @example(i1 %u0, i32 %g) {
entry:
  %b = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  %cg = icmp ne i32 %g, 0
  %r = select i1 %cg, i1 %b, i1 %b
  %b2 = call i1 @cq_theta_i1(i1 %r, double 1.000000e-01)
  br i1 %b, label %arm, label %merge
arm:
  call void @cq_phi(double 9.000000e-01)
  br label %merge
merge:
  %m = call i1 @cq_measure_i1(i1 %b2)
  %z = zext i1 %m to i32
  ret i32 %z
}
