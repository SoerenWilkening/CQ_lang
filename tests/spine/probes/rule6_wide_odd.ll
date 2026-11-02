; cq-hxvx: rule 6's inverse of a mul by an odd literal on a rail wider than 128 bits: the Newton iteration
; for k^-1 mod 2^W runs until it covers W (a fixed 7 steps covered 128 bits). 3^-1 mod 2^200 below.
; CHECK odd_inverse_wide: call i32 @cq_template_mul_i200_hl(i32 %{{t}}, i200 -535646014752996758513987364113720867507400997927597611767125)
declare i64 @cq_theta_ui64(i64, double)

define i200 @odd_inverse_wide(i64 %y0, double %th) {
  %y = call i64 @cq_theta_ui64(i64 %y0, double %th)
  %z = zext i64 %y to i200
  %s = add i200 %z, 1
  %p = mul i200 %s, 3
  ret i200 %p
}
