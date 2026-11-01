; A 2-D table read with two quantum indices (120's flattened form): the linear cell index row * 2 + col
; at the i32 width of the C index expressions (shl by the row stride in cells, add), one QROM over the
; 4 cells; -O1's zexts and the GEP scaling are not emitted.
@G = internal constant [2 x [2 x i32]] [[2 x i32] [i32 1, i32 2], [2 x i32] [i32 3, i32 4]]
declare i32 @cq_theta_ui32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @two_indices(i32 %x0, i32 %y0, double %t) {
  %x = call i32 @cq_theta_ui32(i32 %x0, double %t)
  %y = call i32 @cq_theta_ui32(i32 %y0, double %t)
  %a = and i32 %x, 1
  %b = and i32 %y, 1
  %za = zext nneg i32 %a to i64
  %zb = zext nneg i32 %b to i64
  %e = getelementptr inbounds [2 x [2 x i32]], ptr @G, i64 0, i64 %za, i64 %zb
  %v = load i32, ptr %e, align 4
  %m = call i32 @cq_measure_si32(i32 %v)
  ret i32 %m
}
; CHECK two_indices: %{{r}} = call i32 @cq_template_shl_i32_hl(i32 %{{a}}, i32 1)
; CHECK two_indices: %{{l}} = call i32 @cq_template_add_i32(i32 %{{r}}, i32 %{{b}})
; CHECK two_indices: call i32 @cq_template_qrom_load_i32(ptr @G, i64 4, i32 %{{l}})
; CHECK two_indices: call void @cq_template_add_i32_unc(
; CHECK two_indices: call void @cq_template_shl_i32_hl_unc(
; CHECK-COUNT two_indices: cq_template_zext 0
