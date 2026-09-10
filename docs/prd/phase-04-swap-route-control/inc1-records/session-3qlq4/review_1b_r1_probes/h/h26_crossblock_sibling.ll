define i32 @example(i32 %u1, i32 %g) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %t = trunc i32 %q to i1
  %b = call i1 @cq_theta_i1(i1 %t, double 5.000000e-01)
  %cg = icmp ne i32 %g, 0
  br i1 %cg, label %mid, label %pred
mid:
  %c = call i1 @cq_theta_i1(i1 %t, double 9.000000e-01)
  br label %pred
pred:
  br i1 %b, label %arm, label %merge
arm:
  call void @cq_phi(double 7.000000e-01)
  br label %merge
merge:
  %m = call i1 @cq_measure_i1(i1 %b)
  %z = zext i1 %m to i32
  ret i32 %z
}
