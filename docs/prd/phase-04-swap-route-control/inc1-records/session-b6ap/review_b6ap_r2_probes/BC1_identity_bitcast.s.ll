; ModuleID = 'BC1_identity_bitcast.s1.ll'
source_filename = "BC1_identity_bitcast.s1.ll"

define i32 @example() {
entry:
  %h = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_ry_i32(i32 %h, double 3.000000e-01)
  %h9 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_ry_i32(i32 %h9, double 4.000000e-01)
  %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h, i32 5)
  call void @cqrt_ry_i32_controlled(i32 %h_cmp, i32 %h9, double 9.000000e-01)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h, i32 5)
  call void @cqrt_free(i32 %h_cmp)
  %h_cmp3 = call i32 @cq_template_icmp_eq_i32_hl(i32 %h, i32 5)
  %out = call i32 @cqrt_alloc_i32(i32 0)
  %selop = call i32 @cqrt_alloc_i32(i32 7)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp3, i32 %selop, i32 %out)
  call void @cqrt_x(i32 %h_cmp3)
  %selop4 = call i32 @cqrt_alloc_i32(i32 5)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp3, i32 %selop4, i32 %out)
  call void @cqrt_x(i32 %h_cmp3)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp3, i32 %h, i32 5)
  call void @cqrt_free(i32 %h_cmp3)
  %h_cmp5 = call i32 @cq_template_icmp_eq_i32_hl(i32 %h, i32 5)
  %out6 = call i32 @cqrt_alloc_i32(i32 0)
  %selop7 = call i32 @cqrt_alloc_i32(i32 2)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp5, i32 %selop7, i32 %out6)
  call void @cqrt_x(i32 %h_cmp5)
  %selop8 = call i32 @cqrt_alloc_i32(i32 1)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp5, i32 %selop8, i32 %out6)
  call void @cqrt_x(i32 %h_cmp5)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp5, i32 %h, i32 5)
  call void @cqrt_free(i32 %h_cmp5)
  call void @cqrt_addc_i32(i32 %out, i32 3)
  %m = call i32 @cqrt_measure_i32(i32 %h9)
  %m10 = call i32 @cqrt_measure_i32(i32 %out)
  %m11 = call i32 @cqrt_measure_i32(i32 %out6)
  %s1 = add nsw i32 %m, %m10
  %s2 = add nsw i32 %s1, %m11
  ret i32 %s2
}

define i32 @main() {
  %r = call i32 @example()
  ret i32 0
}

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

declare void @cqrt_x(i32)

declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_copy_i32_controlled(i32, i32, i32)

declare void @cqrt_ry_i32(i32, double)

declare void @cqrt_ry_i32_controlled(i32, i32, double)

declare void @cqrt_addc_i32(i32, i32)

declare i32 @cqrt_measure_i32(i32)
