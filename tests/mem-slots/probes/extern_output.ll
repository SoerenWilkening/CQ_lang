; Rule 20, 71: a rail stored into an extern global is an output: never uncomputed, never freed.
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
@g = global i32 0, align 4

define i32 @extern_output(i32 %x0, double %t, i32 %c) {
  %x = call i32 @cq_theta_si32(i32 %x0, double %t)
  %m = mul i32 %x, %c
  store i32 %m, ptr @g
  %r = call i32 @cq_measure_si32(i32 %x)
  ret i32 %r
}
; CHECK extern_output: store i32 %{{m}}, ptr @g, align 4
; CHECK-COUNT extern_output: _unc( 0
; CHECK-COUNT extern_output: cqrt_free 0
