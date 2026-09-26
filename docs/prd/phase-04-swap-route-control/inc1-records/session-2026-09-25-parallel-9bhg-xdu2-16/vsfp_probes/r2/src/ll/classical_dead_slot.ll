declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

; @h reads `a` and `b` only through ONE empty diamond on `(a > 3) & (b > 5)`: both are
; live in @h (a branch condition is a liveness root), so the dead-argument drop does
; not touch them; the CLONE's flatten removes the diamond and the specializer records
; BOTH slots dead. Slot 0 receives a `cq_theta` result (the backstop's exemption),
; slot 1 a CLASSICAL value — which the backstop must not decline: only a QUANTUM value
; kept alive by a phantom read is a hazard.
define i32 @h(i32 %a, i32 %b, i32 %k) {
entry:
  %c1 = icmp sgt i32 %a, 3
  %c2 = icmp sgt i32 %b, 5
  %c = and i1 %c1, %c2
  br i1 %c, label %t, label %e
t:
  br label %e
e:
  %r = add i32 %k, 1
  ret i32 %r
}

define i32 @main(i32 %m) {
  %q = call i32 @cq_theta_si32(i32 %m, double 5.000000e-01)
  %kk = mul i32 %m, 5
  %t = call i32 @h(i32 %q, i32 %kk, i32 %m)
  %z = call i32 @cq_measure_si32(i32 %q)
  %s = add i32 %z, %t
  ret i32 %s
}
