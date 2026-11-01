; A 3 x 3 table read at an i8 row and an i32 column: the row is widened to i32 by a zext template (the
; linear index's width is the widest index), multiplied by 3 cells (not a power of two: mul_hl), added.
@G = internal constant [3 x [3 x i16]] [[3 x i16] [i16 1, i16 2, i16 3], [3 x i16] [i16 4, i16 5, i16 6], [3 x i16] [i16 7, i16 8, i16 9]]
declare i8 @cq_theta_ui8(i8, double)
declare i32 @cq_theta_ui32(i32, double)
declare i16 @cq_measure_si16(i16)

define i16 @mixed_widths(i8 %x0, i32 %y0, double %t) {
  %x = call i8 @cq_theta_ui8(i8 %x0, double %t)
  %y = call i32 @cq_theta_ui32(i32 %y0, double %t)
  %za = zext i8 %x to i64
  %zb = zext i32 %y to i64
  %e = getelementptr inbounds [3 x [3 x i16]], ptr @G, i64 0, i64 %za, i64 %zb
  %v = load i16, ptr %e, align 2
  %m = call i16 @cq_measure_si16(i16 %v)
  ret i16 %m
}
; CHECK mixed_widths: %{{w}} = call i32 @cq_template_zext_i8_to_i32(i32 %{{x}})
; CHECK mixed_widths: %{{r}} = call i32 @cq_template_mul_i32_hl(i32 %{{w}}, i32 3)
; CHECK mixed_widths: %{{l}} = call i32 @cq_template_add_i32(i32 %{{r}}, i32 %{{y}})
; CHECK mixed_widths: call i32 @cq_template_qrom_load_i16(ptr @G, i64 9, i32 %{{l}})
