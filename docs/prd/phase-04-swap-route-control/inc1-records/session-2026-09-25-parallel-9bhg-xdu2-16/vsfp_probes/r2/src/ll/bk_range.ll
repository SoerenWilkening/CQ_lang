declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)

define i32 @h(i32 range(i32 1, 100) %a, i32 %k) {
  %r = add i32 %k, 1
  ret i32 %r
}

define i32 @main(i32 %m) {
  %lo = trunc i32 %m to i1
  %b = call i1 @cq_theta_i1(i1 %lo, double 5.000000e-01)
  %z = zext i1 %b to i32
  %p = add nuw nsw i32 %z, 1
  %t = call i32 @h(i32 %p, i32 %m)
  %b2 = call i1 @cq_theta_i1(i1 %b, double 7.000000e-01)
  %mm = call i1 @cq_measure_i1(i1 %b2)
  %mz = zext i1 %mm to i32
  %s = add i32 %t, %mz
  ret i32 %s
}
