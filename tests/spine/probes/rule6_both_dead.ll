; cq-12cr: CR rule 6 with both operands of the update dead (owner ruling 2026-10-28).
; @pn (review pass-h2 pn.c): y' = select(x > k, 3, -1) + y. The select is garbage rule 5 uncomputes
; anyway, so the register y is cleaned (t = y' - sel), then the select's _unc runs in its usual place.
; @comp3: g = x << 1 is garbage computed from x; y' = g + x = 3x is a bijection: g is uncomputed first
; and x is cleaned by t = y' * 3^-1. @comp1: y' = (x << 1) - x = x: t = y' + 0. @comp4: y' = 3x + x = 4x
; has no inverse: x is kept (no copy). @chain: s = x << 1, g = s + k, y' = g + x: s is dead after g and
; is cleaned there (t = g - k), so g is no garbage rule 5 can uncompute (its _unc would read the cleaned
; s); at y' neither operand is such garbage: operand 0 (g) is cleaned (t = y' - x), x is kept.
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @pn(i32 %x0, double %tx, i32 %y0, double %ty, i32 %k, double %t) {
  %x = call i32 @cq_theta_si32(i32 %x0, double %tx)
  %y = call i32 @cq_theta_si32(i32 %y0, double %ty)
  %c = icmp sgt i32 %x, %k
  %s = select i1 %c, i32 3, i32 -1
  %u = add nsw i32 %s, %y
  %z = call i32 @cq_theta_si32(i32 %u, double %t)
  %m = call i32 @cq_measure_si32(i32 %z)
  %mx = call i32 @cq_measure_si32(i32 %x)
  %r = add i32 %mx, %m
  ret i32 %r
}
; CHECK-COUNT pn: call void @cqrt_add_i32( 1
; CHECK-COUNT pn: call void @cqrt_copy_i32( 0
; CHECK-COUNT pn: call void @cq_template_select_i32_ll_unc( 1

define i32 @comp3(i32 %x0, double %tx) {
  %x = call i32 @cq_theta_si32(i32 %x0, double %tx)
  %g = shl i32 %x, 1
  %u = add i32 %g, %x
  %m = call i32 @cq_measure_si32(i32 %u)
  ret i32 %m
}
; CHECK comp3: call i32 @cq_template_mul_i32_hl(i32 %{{u}}, i32 -1431655765)
; CHECK-COUNT comp3: call void @cqrt_copy_i32( 1
; CHECK-COUNT comp3: call void @cq_template_shl_i32_hl_unc( 1

define i32 @comp1(i32 %x0, double %tx) {
  %x = call i32 @cq_theta_si32(i32 %x0, double %tx)
  %g = shl i32 %x, 1
  %u = sub i32 %g, %x
  %m = call i32 @cq_measure_si32(i32 %u)
  ret i32 %m
}
; CHECK comp1: call i32 @cq_template_add_i32_hl(i32 %{{u}}, i32 0)
; CHECK-COUNT comp1: call void @cqrt_copy_i32( 1

define i32 @comp4(i32 %x0, double %tx) {
  %x = call i32 @cq_theta_si32(i32 %x0, double %tx)
  %g = mul i32 %x, 3
  %u = add i32 %g, %x
  %m = call i32 @cq_measure_si32(i32 %u)
  ret i32 %m
}
; CHECK-COUNT comp4: call void @cqrt_copy_i32( 0

define i32 @chain(i32 %x0, double %tx, i32 %k) {
  %x = call i32 @cq_theta_si32(i32 %x0, double %tx)
  %s = shl i32 %x, 1
  %g = add i32 %s, %k
  %u = add i32 %g, %x
  %m = call i32 @cq_measure_si32(i32 %u)
  ret i32 %m
}
; CHECK chain: call void @cqrt_addc_i32(i32 %2, i32 %k)
; CHECK chain: call void @cqrt_add_i32(i32 %1, i32 %2)
; CHECK-COUNT chain: call void @cqrt_copy_i32( 0
