; Rule 20, forwarding: a local slot object whose every load is dominated by a store of the same cell
; with nothing in between. The loads are bound to the stored handles (no load emitted); the stored
; product is garbage and is uncomputed and freed (rule 5).
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @static_local(i32 %x0, double %t, i32 %c) {
  %a = alloca [4 x i32], align 16
  %x = call i32 @cq_theta_si32(i32 %x0, double %t)
  %m = mul i32 %x, %c
  %p1 = getelementptr inbounds i8, ptr %a, i64 4
  store i32 %m, ptr %p1
  store i32 %x, ptr %a
  %l1 = load i32, ptr %p1
  %l0 = load i32, ptr %a
  %s = add i32 %l1, %l0
  %r = call i32 @cq_measure_si32(i32 %s)
  ret i32 %r
}
; CHECK static_local: alloca i32, i64 4, align 16
; CHECK static_local: %{{m}} = call i32 @cq_template_mul_i32_hl(i32 %{{x}}, i32 %{{c}})
; CHECK static_local: store i32 %{{m}}, ptr %{{p}}, align 4
; CHECK static_local: @cq_template_add_i32(i32 %{{m}}, i32 %{{x}})
; CHECK static_local: call void @cq_template_mul_i32_hl_unc(
; CHECK-COUNT static_local: load i32 0
; CHECK-COUNT static_local: call void @cqrt_free( 1
