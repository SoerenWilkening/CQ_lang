define i32 @example(i1 %g, i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 3.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 4.000000e-01)
  br i1 %g, label %L, label %R
L:
  br label %J
R:
  br label %J
J:
  %p = phi i32 [ %q, %L ], [ %r, %R ]
  %b = call i32 @cq_theta_si32(i32 %p, double 5.000000e-01)
  %c = call i32 @cq_theta_si32(i32 %q, double 9.000000e-01)
  %e = icmp eq i32 %b, 1
  br i1 %e, label %arm, label %merge
arm:
  call void @cq_phi(double 7.000000e-01)
  br label %merge
merge:
  %m = call i32 @cq_measure_si32(i32 %c)
  ret i32 %m
}
