declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

; @inner reads `a` only through an EMPTY diamond (live in @inner, dead in its clone).
define i32 @inner(i32 %a, i32 %k) noinline {
entry:
  %c = icmp sgt i32 %a, 3
  br i1 %c, label %t, label %e
t:
  br label %e
e:
  %r = add i32 %k, 1
  ret i32 %r
}

; @h derives `p` from its quantum argument and passes it ONLY to @inner's slot 0.
define i32 @h(i32 %a, i32 %k) {
  %p = add i32 %a, 1
  %r = call i32 @inner(i32 %p, i32 %k)
  ret i32 %r
}

define i32 @main(i32 %m) {
  %q = call i32 @cq_theta_si32(i32 %m, double 5.000000e-01)
  %t = call i32 @h(i32 %q, i32 %m)
  %q2 = call i32 @cq_theta_si32(i32 %q, double 7.000000e-01)
  %z = call i32 @cq_measure_si32(i32 %q2)
  %s = add i32 %z, %t
  ret i32 %s
}
