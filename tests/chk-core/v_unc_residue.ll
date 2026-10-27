; Violation test: v_unc_residue
target triple = "x86_64-apple-macosx16.0.0"
define i32 @v(i32 %x0, double %th) {
  %x = call i32 @cqrt_alloc_i32(i32 %x0)
  call void @cqrt_ry_i32(i32 %x, double %th)
  %y = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)
  call void @cq_template_add_i32_hl_unc(i32 %y, i32 %x, i32 2)
  call void @cqrt_free(i32 %y)
  %m = call i32 @cqrt_measure_i32(i32 %x)
  ret i32 %m
}
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_sub_i32_hl(i32, i32)
