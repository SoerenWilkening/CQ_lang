; Rule 20 index arithmetic on a QRAM index rail (192, 191): a quantum index plus a constant element
; offset is add_hl at the C index width (32, an i8 index sign-extended first); a 2-D index is flattened
; r * cols + c (mul_hl by the row length, then add).
declare i32 @cq_theta_ui32(i32, double)
declare i8 @cq_theta_ui8(i8, double)
declare i32 @cq_measure_ui32(i32)

define i32 @qram_plus_one(i32 %x0, double %t, i32 %v) {
  %a = alloca [8 x i32], align 16
  %x = call i32 @cq_theta_ui32(i32 %x0, double %t)
  %i = and i32 %x, 3
  %iz = zext nneg i32 %i to i64
  %p = getelementptr inbounds i32, ptr %a, i64 %iz
  %p1 = getelementptr inbounds i8, ptr %p, i64 4
  store i32 %v, ptr %p1, align 4
  %r = load i32, ptr %a, align 4
  %m = call i32 @cq_measure_ui32(i32 %r)
  ret i32 %m
}
; CHECK qram_plus_one: call i32 @cq_template_add_i32_hl(i32 %{{i}}, i32 1)
; CHECK qram_plus_one: call void @cqrt_qram_store_i32(

define i32 @qram_sext_off(i8 %x0, double %t, i32 %v) {
  %a = alloca [300 x i32], align 16
  %x = call i8 @cq_theta_ui8(i8 %x0, double %t)
  %is = sext i8 %x to i64
  %p = getelementptr inbounds i32, ptr %a, i64 %is
  %p1 = getelementptr inbounds i8, ptr %p, i64 800
  store i32 %v, ptr %p1, align 4
  %r = load i32, ptr %a, align 4
  %m = call i32 @cq_measure_ui32(i32 %r)
  ret i32 %m
}
; CHECK qram_sext_off: call i32 @cq_template_sext_i8_to_i32(i32 %{{x}})
; CHECK qram_sext_off: call i32 @cq_template_add_i32_hl(i32 %{{w}}, i32 200)

define i32 @qram_flat(i32 %r0, double %tr, i32 %c0, double %tc, i32 %v) {
  %g = alloca [4 x [4 x i32]], align 16
  %r = call i32 @cq_theta_ui32(i32 %r0, double %tr)
  %c = call i32 @cq_theta_ui32(i32 %c0, double %tc)
  %ri = and i32 %r, 3
  %rz = zext nneg i32 %ri to i64
  %ci = and i32 %c, 3
  %cz = zext nneg i32 %ci to i64
  %p = getelementptr inbounds [4 x [4 x i32]], ptr %g, i64 0, i64 %rz, i64 %cz
  store i32 %v, ptr %p, align 4
  %q = getelementptr inbounds i8, ptr %g, i64 24
  %l = load i32, ptr %q, align 8
  %m = call i32 @cq_measure_ui32(i32 %l)
  ret i32 %m
}
; CHECK qram_flat: call i32 @cq_template_mul_i32_hl(i32 %{{ri}}, i32 4)
; CHECK qram_flat: call i32 @cq_template_add_i32(i32 %{{rm}}, i32 %{{ci}})
; CHECK qram_flat: call i32 @cqrt_qram_load_i32_hl(i32 %{{g}}, i32 6)
