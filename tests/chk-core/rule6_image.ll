; cq-o9mx (CR rule 5 sentence 1, rule 6, rulings 2 A): a rule-6 image is kept whether or not a rotated register's
; content reaches it. @img: s = v + old (v, old plain rails) cleans old against s (t = s - v; old ^= t; t _unc against
; s, v; free old): s and v are operands of the inverse: role rule6_image. Everything else stays a leak:
;   %g  an ordinary template result left live, derived from s itself
;   %u  a copy taken and un-copied: copy(%p, %c) twice cleans nothing: %p's operand %q stays garbage
;   %l  a bus load's copy read by a rule-6 inverse: rule 5, a load copy is never cleaned by rule 6, so no image
target triple = "x86_64-apple-macosx16.0.0"
define i32 @img(i32 %v0, i32 %o0) {
  %m = call i32 @__cq_mem()
  %a = alloca i32
  store i32 %v0, ptr %a
  %ai = ptrtoint ptr %a to i64
  %v = call i32 @cqrt_alloc_i32(i32 %v0)
  call void @cqrt_ry_i32(i32 %v, double 0.0)
  %vv = call i32 @cq_template_add_i32_hl(i32 %v, i32 1)
  %old = call i32 @cq_template_add_i32_hl(i32 %v, i32 %o0)
  %s = call i32 @cq_template_add_i32(i32 %vv, i32 %old)
  %t = call i32 @cq_template_sub_i32(i32 %s, i32 %vv)
  call void @cqrt_copy_i32(i32 %t, i32 %old)
  call void @cq_template_sub_i32_unc(i32 %t, i32 %s, i32 %vv)
  call void @cqrt_free(i32 %t)
  call void @cqrt_free(i32 %old)
  %g = call i32 @cq_template_shl_i32_hl(i32 %s, i32 1)
  %q = call i32 @cq_template_add_i32_hl(i32 %v, i32 2)
  %p = call i32 @cq_template_add_i32_hl(i32 %q, i32 3)
  %c = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %p, i32 %c)
  call void @cqrt_copy_i32(i32 %p, i32 %c)
  call void @cqrt_free(i32 %c)
  call void @cq_template_add_i32_hl_unc(i32 %p, i32 %q, i32 3)
  call void @cqrt_free(i32 %p)
  %l = call i32 @cqrt_qram_load_i32_hl(i32 %m, i64 %ai)
  %o2 = call i32 @cq_template_add_i32_hl(i32 %v, i32 5)
  %s2 = call i32 @cq_template_add_i32(i32 %l, i32 %o2)
  %t2 = call i32 @cq_template_sub_i32(i32 %s2, i32 %l)
  call void @cqrt_copy_i32(i32 %t2, i32 %o2)
  call void @cqrt_free(i32 %o2)
  call void @cq_template_sub_i32_unc(i32 %t2, i32 %s2, i32 %l)
  call void @cqrt_free(i32 %t2)
  ret i32 %o0
}
declare i32 @__cq_mem()
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_copy_i32(i32, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_qram_load_i32_hl(i32, i64)
declare i32 @cq_template_add_i32(i32, i32)
declare i32 @cq_template_sub_i32(i32, i32)
declare void @cq_template_sub_i32_unc(i32, i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_shl_i32_hl(i32, i32)
