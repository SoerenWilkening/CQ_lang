define i32 @example(i1 %u0, i32 %u1) {
entry:
  %b = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  %q = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %c = icmp eq i32 %q, 5
  %c2 = icmp eq i32 %q, 7
  %a1 = and i1 %b, %c
  %a2 = and i1 %b, %c2
  %t = or i1 %a1, %a2
  br i1 %t, label %arm, label %merge
arm:
  call void @cq_phi(double 7.000000e-01)
  br label %merge
merge:
  %m = call i1 @cq_measure_i1(i1 %b)
  %z = zext i1 %m to i32
  %n = call i32 @cq_measure_si32(i32 %q)
  %r = add i32 %n, %z
  ret i32 %r
}
