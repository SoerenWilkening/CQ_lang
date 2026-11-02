; cq-qhow (CR rule 19, §6 item 1): a rule-6 image of a rotated register carries its content and is FROZEN at
; exit, across a call: @img cleans x against r = x + c (t = r - c; x ^= t; t _unc against r) and returns r;
; @use keeps it. A temp written from the rotated x and left live (%g) carries nothing and stays garbage; so
; does the shifted copy of the image (%s), which no write into a frozen rail read.
target triple = "x86_64-apple-macosx16.0.0"
define i32 @img(i32 %x0, double %th, i32 %c) noinline {
  %x = call i32 @cqrt_alloc_i32(i32 %x0)
  call void @cqrt_ry_i32(i32 %x, double %th)
  %g = call i32 @cq_template_add_i32_hl(i32 %x, i32 7)
  %r = call i32 @cq_template_add_i32_hl(i32 %x, i32 %c)
  %t = call i32 @cq_template_sub_i32_hl(i32 %r, i32 %c)
  call void @cqrt_copy_i32(i32 %t, i32 %x)
  call void @cq_template_sub_i32_hl_unc(i32 %t, i32 %r, i32 %c)
  call void @cqrt_free(i32 %t)
  call void @cqrt_free(i32 %x)
  ret i32 %r
}
define i32 @use(i32 %x0, double %th, i32 %c) {
  %q = call i32 @img(i32 %x0, double %th, i32 %c)
  %s = call i32 @cq_template_shl_i32_hl(i32 %q, i32 1)
  ret i32 %c
}
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_copy_i32(i32, i32)
declare void @cqrt_free(i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare i32 @cq_template_sub_i32_hl(i32, i32)
declare void @cq_template_sub_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_shl_i32_hl(i32, i32)
