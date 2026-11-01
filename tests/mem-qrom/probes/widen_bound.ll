; A 64 x 64 byte table at two i8 indices: the linear index reaches 4095, past i8, so it is computed at
; 12 bits (the width of the largest in-domain cell index n - 1): both indices zext to i12, shl by 6.
@G = internal global [64 x [64 x i8]] zeroinitializer
declare i8 @cq_theta_ui8(i8, double)
declare i8 @cq_measure_si8(i8)

define i8 @widen_bound(i8 %x0, i8 %y0, double %t) {
  %x = call i8 @cq_theta_ui8(i8 %x0, double %t)
  %y = call i8 @cq_theta_ui8(i8 %y0, double %t)
  %a = and i8 %x, 63
  %b = and i8 %y, 63
  %za = zext nneg i8 %a to i64
  %zb = zext nneg i8 %b to i64
  %e = getelementptr inbounds [64 x [64 x i8]], ptr @G, i64 0, i64 %za, i64 %zb
  %v = load i8, ptr %e, align 1
  %m = call i8 @cq_measure_si8(i8 %v)
  ret i8 %m
}
; CHECK widen_bound: %{{wa}} = call i32 @cq_template_zext_i8_to_i12(i32 %{{a}})
; CHECK widen_bound: %{{r}} = call i32 @cq_template_shl_i12_hl(i32 %{{wa}}, i12 6)
; CHECK widen_bound: %{{wb}} = call i32 @cq_template_zext_i8_to_i12(i32 %{{b}})
; CHECK widen_bound: %{{l}} = call i32 @cq_template_add_i12(i32 %{{r}}, i32 %{{wb}})
; CHECK widen_bound: call i32 @cq_template_qrom_load_i8(ptr @G, i64 4096, i32 %{{l}})
