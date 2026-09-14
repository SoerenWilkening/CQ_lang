; CONTROL for j1739_undef_pairing.ll: identical but with a REAL literal.
; This one is genuinely sound and must stay OK under the fix.
declare i32 @cqrt_alloc_i32(i32)
declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)
declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)
declare void @cqrt_free(i32)
define void @f() {
  %h = call i32 @cqrt_alloc_i32(i32 3)
  %c = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 7)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %c, i32 %h, i32 7)
  call void @cqrt_free(i32 %c)
  ret void
}
