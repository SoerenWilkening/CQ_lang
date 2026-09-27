declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @h(i32 %a, i32 %k) {
  %r = add i32 %k, 1
  ret i32 %r
}

define i32 @g(i32 %a, i32 %k) {
  %r = musttail call i32 @h(i32 %a, i32 %k)
  ret i32 %r
}

define i32 @main(i32 %m) {
  %q = call i32 @cq_theta_si32(i32 %m, double 5.000000e-01)
  %z = call i32 @cq_measure_si32(i32 %q)
  %t = call i32 @g(i32 %m, i32 %z)
  %s = add i32 %t, %z
  ret i32 %s
}
