; M1 handler order (cq-f69): first acceptor wins (i8), a decline's writes are discarded (i32).
target triple = "x86_64-apple-macosx16.0.0"
define i32 @v(i32 %x0, double %th) {
  %t8 = trunc i32 %x0 to i8
  %a = call i32 @cqrt_alloc_i8(i8 %t8)
  %p = call i32 @cq_template_mul_i8_hl(i32 %a, i8 3)
  %b = call i32 @cqrt_alloc_i32(i32 %x0)
  %q = call i32 @cq_template_mul_i32_hl(i32 %b, i32 5)
  %pm = call signext i8 @cqrt_measure_i8(i32 %p)
  %qm = call i32 @cqrt_measure_i32(i32 %q)
  ret i32 %qm
}
declare i32 @cqrt_alloc_i8(i8)
declare i32 @cqrt_alloc_i32(i32)
declare signext i8 @cqrt_measure_i8(i32)
declare i32 @cqrt_measure_i32(i32)
declare i32 @cq_template_mul_i8_hl(i32, i8)
declare i32 @cq_template_mul_i32_hl(i32, i32)
