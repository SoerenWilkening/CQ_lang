; cq-n6a0: an entry returning an unmeasured quantum value returns the rail's handle (CR §1.1)
target triple = "x86_64-apple-macosx16.0.0"
define i32 @hret(i32 %x0, double %th, i32 %c) {
  %x = call i32 @cqrt_alloc_i32(i32 %x0)
  call void @cqrt_ry_i32(i32 %x, double %th)
  %q = call i32 @cq_template_add_i32_hl(i32 %x, i32 %c)
  ret i32 %q
}
define i32 @cret(i32 %x0, double %th, i32 %c) {
  %x = call i32 @cqrt_alloc_i32(i32 %x0)
  call void @cqrt_ry_i32(i32 %x, double %th)
  %m = call i32 @cqrt_measure_i32(i32 %x)
  %r = add i32 %m, %c
  ret i32 %r
}
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cqrt_measure_i32(i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
