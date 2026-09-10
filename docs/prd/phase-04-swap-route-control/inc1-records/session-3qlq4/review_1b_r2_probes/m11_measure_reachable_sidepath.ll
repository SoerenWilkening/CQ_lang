define i32 @example(i1 %g, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %t = trunc i32 %q to i1
  %b = call i1 @cq_theta_i1(i1 %t, double 5.000000e-01)
  br i1 %g, label %mid, label %pred
mid:
  %m = call i1 @cq_measure_i1(i1 %b)
  br label %pred
pred:
  br i1 %b, label %arm, label %merge
arm:
  call void @cq_phi(double 7.000000e-01)
  br label %merge
merge:
  ret i32 0
}
