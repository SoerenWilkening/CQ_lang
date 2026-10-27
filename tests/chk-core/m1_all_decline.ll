; M1 handler order (cq-f69): every handler declining is no_family; a duplicate registration is a no-op (i64).
target triple = "x86_64-apple-macosx16.0.0"
define i32 @v(i32 %x0, double %th) {
  %w = sext i32 %x0 to i64
  %a = call i32 @cqrt_alloc_i64(i64 %w)
  %p = call i32 @cq_template_mul_i64_hl(i32 %a, i64 3)
  ret i32 0
}
declare i32 @cqrt_alloc_i64(i64)
declare i32 @cq_template_mul_i64_hl(i32, i64)
