; M1 handler order (cq-f69): a handler returning -1 after cqe_fail ends the search (i16).
target triple = "x86_64-apple-macosx16.0.0"
define i32 @v(i32 %x0, double %th) {
  %t = trunc i32 %x0 to i16
  %a = call i32 @cqrt_alloc_i16(i16 %t)
  %p = call i32 @cq_template_mul_i16_hl(i32 %a, i16 3)
  %pm = call signext i16 @cqrt_measure_i16(i32 %p)
  ret i32 0
}
declare i32 @cqrt_alloc_i16(i16)
declare i32 @cq_template_mul_i16_hl(i32, i16)
declare signext i16 @cqrt_measure_i16(i32)
