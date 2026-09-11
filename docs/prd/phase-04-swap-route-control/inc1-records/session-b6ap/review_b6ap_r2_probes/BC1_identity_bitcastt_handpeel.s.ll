; ModuleID = 'BC1_identity_bitcastt_handpeel.s1.ll'
source_filename = "BC1_identity_bitcastt_handpeel.s1.ll"

define i32 @example() {
entry:
  %h = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_ry_i32(i32 %h, double 3.000000e-01)
  %h7 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_ry_i32(i32 %h7, double 4.000000e-01)
  %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h, i32 5)
  call void @cqrt_ry_i32_controlled(i32 %h_cmp, i32 %h7, double 9.000000e-01)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h, i32 5)
  call void @cqrt_free(i32 %h_cmp)
  %h_cmp1 = call i32 @cq_template_icmp_eq_i32_hl(i32 %h, i32 5)
  %out = call i32 @cqrt_alloc_i32(i32 0)
  %selop = call i32 @cqrt_alloc_i32(i32 7)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp1, i32 %selop, i32 %out)
  call void @cqrt_x(i32 %h_cmp1)
  %selop2 = call i32 @cqrt_alloc_i32(i32 5)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp1, i32 %selop2, i32 %out)
  call void @cqrt_x(i32 %h_cmp1)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp1, i32 %h, i32 5)
  call void @cqrt_free(i32 %h_cmp1)
  %h_cmp3 = call i32 @cq_template_icmp_eq_i32_hl(i32 %h, i32 5)
  %out4 = call i32 @cqrt_alloc_i32(i32 0)
  %selop5 = call i32 @cqrt_alloc_i32(i32 2)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp3, i32 %selop5, i32 %out4)
  call void @cqrt_x(i32 %h_cmp3)
  %selop6 = call i32 @cqrt_alloc_i32(i32 1)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp3, i32 %selop6, i32 %out4)
  call void @cqrt_x(i32 %h_cmp3)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp3, i32 %h, i32 5)
  call void @cqrt_free(i32 %h_cmp3)
  call void @cqrt_addc_i32(i32 %out, i32 3)
  %m = call i32 @cqrt_measure_i32(i32 %h7)
  %m8 = call i32 @cqrt_measure_i32(i32 %out)
  %m9 = call i32 @cqrt_measure_i32(i32 %out4)
  %s1 = add nsw i32 %m, %m8
  %s2 = add nsw i32 %s1, %m9
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
