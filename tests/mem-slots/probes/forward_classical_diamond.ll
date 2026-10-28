; Forwarding across a classical diamond: the store dominates the load and neither arm writes the cell, so
; the load is the stored rail (no load emitted); the stored product is garbage, uncomputed and freed.
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @forward_classical_diamond(i32 %x0, double %t, i32 %c, i1 %b) {
entry:
  %a = alloca i32, align 4
  %x = call i32 @cq_theta_si32(i32 %x0, double %t)
  %m = mul i32 %x, %c
  store i32 %m, ptr %a
  br i1 %b, label %l, label %r
l:
  %u = add i32 %c, 1
  br label %j
r:
  br label %j
j:
  %v = load i32, ptr %a
  %s = add i32 %v, %x
  %o = call i32 @cq_measure_si32(i32 %s)
  ret i32 %o
}
; CHECK forward_classical_diamond: @cq_template_add_i32(i32 %{{m}}, i32 %{{x}})
; CHECK-COUNT forward_classical_diamond: load i32 0
; CHECK-COUNT forward_classical_diamond: call void @cqrt_free( 1
