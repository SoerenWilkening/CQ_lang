define i32 @example(i1 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %c = icmp eq i32 %q, 5
  br i1 %c, label %mid, label %out
mid:
  call void @cq_phi(double 2.000000e-01)
  %b = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  br i1 %b, label %inner, label %out
inner:
  call void @cq_phi(double 9.000000e-01)
  br label %out
out:
  %n = call i32 @cq_measure_si32(i32 %q)
  ret i32 %n
}
