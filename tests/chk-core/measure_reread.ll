; cq-ihlt (CR rule 2, BACKEND_ABI 1.3): a cqrt_measure of a rail already measured is a classical
; re-read: it returns the outcome and logs no second measure event.
target triple = "x86_64-apple-macosx16.0.0"
define i32 @v(i32 %x0, double %th) {
  %x = call i32 @cqrt_alloc_i32(i32 %x0)
  call void @cqrt_ry_i32(i32 %x, double %th)
  %m = call i32 @cqrt_measure_i32(i32 %x)
  %r = call i32 @cqrt_measure_i32(i32 %x)
  %s = add i32 %m, %r
  ret i32 %s
}
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cqrt_measure_i32(i32)
