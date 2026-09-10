define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %e = icmp eq i32 %q, 1
  %x = xor i32 %q, 7
  %c = call i32 @cq_theta_si32(i32 %x, double 9.000000e-01)
  br i1 %e, label %arm, label %merge
arm:
  call void @cq_phi(double 7.000000e-01)
  br label %merge
merge:
  %m = call i32 @cq_measure_si32(i32 %c)
  ret i32 %m
}
