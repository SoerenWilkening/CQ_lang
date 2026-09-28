; ModuleID = 'pf_postfold_noread_swap.ll'
source_filename = "pf_postfold_noread_swap.ll"

define i32 @example(i32 %m, i32 %s) {
entry:
  %h = call i32 @cqrt_alloc_i32(i32 %m)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  call void @cqrt_ry_i32(i32 %h, double -5.000000e-01)
  call void @cqrt_free(i32 %h)
  %h1 = call i32 @cqrt_alloc_i32(i32 7)
  call void @cqrt_ry_i32(i32 %h1, double 4.000000e-01)
  %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h1, i32 3)
  %h2 = call i32 @cqrt_alloc_i32(i32 %s)
  call void @cqrt_ry_i32_controlled(i32 %h_cmp, i32 %h2, double 9.000000e-01)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp, i32 %h1, i32 3)
  call void @cqrt_free(i32 %h_cmp)
  %m3 = call i32 @cqrt_measure_i32(i32 %h2)
  %m4 = call i32 @cqrt_measure_i32(i32 %h1)
  %a = add nsw i32 %m4, %m3
  ret i32 %a
}

declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)

declare void @cqrt_x(i32)

declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_ry_i32_controlled(i32, i32, double)

declare i32 @cqrt_measure_i32(i32)
