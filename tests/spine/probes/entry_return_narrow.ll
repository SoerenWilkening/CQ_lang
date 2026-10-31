; cq-albd (rule 19 at CQ_spec 75588cd, 193; was the cq-juf6 fatal probe, review pass-h3 976_u06): an
; entry returning an unmeasured quantum value returns the i32 handle when its C return type cannot hold
; it (_Bool, char, short, float); the parameter list keeps the C ABI and the C return attributes go.
; An i64 return keeps its type and carries the handle zero-extended.
declare i1 @cq_theta_i1(i1, double)
declare i8 @cq_theta_si8(i8, double)
declare i16 @cq_theta_si16(i16, double)
declare float @cq_theta_f32(float, double)
declare i64 @cq_theta_sl(i64, double)

; CHECK u06: define i32 @u06(i1 noundef zeroext %b0, double %t)
; CHECK u06: ret i32 %{{h}}
define noundef zeroext i1 @u06(i1 noundef zeroext %b0, double %t) {
entry:
  %b = call i1 @cq_theta_i1(i1 %b0, double %t)
  ret i1 %b
}

; CHECK c8: define i32 @c8(i8 signext %c0, double %t)
; CHECK c8: ret i32 %{{h}}
define signext i8 @c8(i8 signext %c0, double %t) {
entry:
  %c = call i8 @cq_theta_si8(i8 %c0, double %t)
  ret i8 %c
}

; CHECK s16: define i32 @s16(i16 signext %s0, double %t, i16 signext %k)
; CHECK s16: ret i32 %{{h}}
define signext i16 @s16(i16 signext %s0, double %t, i16 signext %k) {
entry:
  %s = call i16 @cq_theta_si16(i16 %s0, double %t)
  %r = add i16 %s, %k
  ret i16 %r
}

; CHECK f32: define i32 @f32(float %f0, double %t)
; CHECK f32: ret i32 %{{h}}
define float @f32(float %f0, double %t) {
entry:
  %f = call float @cq_theta_f32(float %f0, double %t)
  ret float %f
}

; CHECK l64: define i64 @l64(i64 %x0, double %t)
; CHECK l64: zext i32 %{{h}} to i64
define i64 @l64(i64 %x0, double %t) {
entry:
  %x = call i64 @cq_theta_sl(i64 %x0, double %t)
  ret i64 %x
}
