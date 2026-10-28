; Rule 20 length from a constant range fact over a parameter: t[(x >> 28)] reads at most 16 entries;
; t[x] with an i16 register reads 2^16.
declare i32 @cq_theta_ui32(i32, double)
declare i16 @cq_theta_ui16(i16, double)
declare i32 @cq_measure_si32(i32)

define i32 @range_param(i32 %x0, i16 %y0, double %t, ptr %p) {
  %x = call i32 @cq_theta_ui32(i32 %x0, double %t)
  %h = lshr i32 %x, 28
  %z = zext nneg i32 %h to i64
  %e = getelementptr inbounds i32, ptr %p, i64 %z
  %v = load i32, ptr %e, align 4
  %y = call i16 @cq_theta_ui16(i16 %y0, double %t)
  %zy = zext i16 %y to i64
  %f = getelementptr inbounds i32, ptr %p, i64 %zy
  %w = load i32, ptr %f, align 4
  %s = add i32 %v, %w
  %m = call i32 @cq_measure_si32(i32 %s)
  ret i32 %m
}
; CHECK range_param: call i32 @cq_template_qrom_load_i32(ptr %{{p}}, i64 16, i32 %{{h}})
; CHECK range_param: call i32 @cq_template_qrom_load_i32(ptr %{{p}}, i64 65536, i32 %{{y}})
; CHECK range_param: call void @cq_template_qrom_load_i32_unc(
