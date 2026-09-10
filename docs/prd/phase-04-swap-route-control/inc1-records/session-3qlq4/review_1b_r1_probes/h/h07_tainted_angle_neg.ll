define i32 @example(i1 %u0, i32 %u1) {
entry:
  %b = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  %q = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %t = sitofp i32 %q to double
  br i1 %b, label %merge, label %arm
arm:
  call void @cq_phi(double %t)
  br label %merge
merge:
  %m = call i1 @cq_measure_i1(i1 %b)
  %z = zext i1 %m to i32
  %n = call i32 @cq_measure_si32(i32 %q)
  %r = add i32 %n, %z
  ret i32 %r
}
