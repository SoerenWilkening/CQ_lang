; A field of a 2-D array of structs at two quantum indices: the cell stride is the struct (8 bytes),
; the strided form over @G + 4 with the flattened index row * 2 + col, 4 cells.
@G = internal constant [2 x [2 x { i32, i32 }]] [[2 x { i32, i32 }] [{ i32, i32 } { i32 1, i32 2 }, { i32, i32 } { i32 3, i32 4 }], [2 x { i32, i32 }] [{ i32, i32 } { i32 5, i32 6 }, { i32, i32 } { i32 7, i32 8 }]]
declare i32 @cq_theta_ui32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @field_2d(i32 %x0, i32 %y0, double %t) {
  %x = call i32 @cq_theta_ui32(i32 %x0, double %t)
  %y = call i32 @cq_theta_ui32(i32 %y0, double %t)
  %a = and i32 %x, 1
  %b = and i32 %y, 1
  %za = zext nneg i32 %a to i64
  %zb = zext nneg i32 %b to i64
  %e = getelementptr inbounds [2 x [2 x { i32, i32 }]], ptr @G, i64 0, i64 %za, i64 %zb, i32 1
  %v = load i32, ptr %e, align 4
  %m = call i32 @cq_measure_si32(i32 %v)
  ret i32 %m
}
; CHECK field_2d: %{{r}} = call i32 @cq_template_shl_i32_hl(i32 %{{a}}, i32 1)
; CHECK field_2d: %{{l}} = call i32 @cq_template_add_i32(i32 %{{r}}, i32 %{{b}})
; CHECK field_2d: call i32 @cq_template_qrom_load_i32_s(ptr getelementptr inbounds (i8, ptr @G, i64 4), i64 4, i64 8, i32 %{{l}})
