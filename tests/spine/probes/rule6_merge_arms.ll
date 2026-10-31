; cq-hge5: CR rule 6 for a select whose two arms are both bijective updates of y (neither arm is y
; itself; review pass-h2 pu.c, 920_pu): y' = (x > k) ? y * 3 : y ^ 7. The old y is cleaned once, by
; the select's merge clean-up t = select(c, y' * 3^-1, y' ^ 7), after both arms are uncomputed; the
; xor arm alone does not clean y (the mul arm, still read by the select, needs y for its uncompute).
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @pu(i32 %x0, double %tx, i32 %y0, double %ty, i32 %k, double %t) {
  %x = call i32 @cq_theta_si32(i32 %x0, double %tx)
  %y = call i32 @cq_theta_si32(i32 %y0, double %ty)
  %c = icmp sgt i32 %x, %k
  %a = mul nsw i32 %y, 3
  %b = xor i32 %y, 7
  %s = select i1 %c, i32 %a, i32 %b
  %z = call i32 @cq_theta_si32(i32 %s, double %t)
  %m = call i32 @cq_measure_si32(i32 %z)
  %mx = call i32 @cq_measure_si32(i32 %x)
  %r = add i32 %mx, %m
  ret i32 %r
}
; CHECK pu: call i32 @cq_template_mul_i32_hl(i32 %{{s}}, i32 -1431655765)
; CHECK-COUNT pu: call void @cqrt_copy_i32( 1
; CHECK-COUNT pu: call i32 @cq_template_select_i32( 2
; CHECK-COUNT pu: call void @cq_template_mul_i32_hl_unc( 2
; CHECK-COUNT pu: call void @cq_template_xor_i32_hl_unc( 2
