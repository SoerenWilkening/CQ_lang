; ModuleID = 'r5_round2_phidesc.ll'
source_filename = "r5_round2_phidesc.ll"

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none)
define internal fastcc i32 @f(i32 %x) unnamed_addr #0 {
  %a = mul nsw i32 %x, 3
  %b = add nsw i32 %a, 1
  ret i32 %b
}

define i32 @example() {
entry:
  %h = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %r = call fastcc i32 @f(i32 4) #1
  %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h, i32 1)
  %out1 = call i32 @cqrt_alloc_i32(i32 0)
  %selop = call i32 @cqrt_alloc_i32(i32 %r)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %selop, i32 %out1)
  call void @cqrt_x(i32 %h_cmp)
  %selop2 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %selop2, i32 %out1)
  call void @cqrt_x(i32 %h_cmp)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h, i32 1)
  call void @cqrt_free(i32 %h_cmp)
  %h_cmp3 = call i32 @cq_template_icmp_eq_i32_hl(i32 %out1, i32 13)
  %h4 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_ry_i32_controlled(i32 %h_cmp3, i32 %h4, double 5.000000e-01)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp3, i32 %out1, i32 13)
  call void @cqrt_free(i32 %h_cmp3)
  %h_cast = call i32 @cq_template_zext_i32_to_i64(i32 %out1)
  call void @cqrt_addc_i64(i32 %h_cast, i64 -13)
  %h_cast5 = call i32 @cq_template_zext_i32_to_i64(i32 %h4)
  %h_op = call i32 @cq_template_mul_i64(i32 %h_cast, i32 %h_cast5)
  %h_cast6 = call i32 @cq_template_trunc_i64_to_i32(i32 %h_op)
  call void @cq_template_mul_i64_unc(i32 %h_op, i32 %h_cast, i32 %h_cast5)
  call void @cqrt_free(i32 %h_op)
  call void @cq_template_zext_i32_to_i64_unc(i32 %h_cast5, i32 %h4)
  call void @cqrt_free(i32 %h_cast5)
  call void @cqrt_addc_i64(i32 %h_cast, i64 13)
  call void @cq_template_zext_i32_to_i64_unc(i32 %h_cast, i32 %out1)
  call void @cqrt_free(i32 %h_cast)
  %m = call i32 @cqrt_measure_i32(i32 %h)
  %m7 = call i32 @cqrt_measure_i32(i32 %h4)
  %m8 = call i32 @cqrt_measure_i32(i32 %h_cast6)
  %s1 = add nsw i32 %m, %m7
  %s2 = add nsw i32 %s1, %m8
  ret i32 %s2
}

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_copy_i32_controlled(i32, i32, i32)

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

declare void @cqrt_x(i32)

declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cqrt_ry_i32(i32, double)

declare void @cqrt_ry_i32_controlled(i32, i32, double)

declare void @cqrt_addc_i64(i32, i64)

declare i32 @cq_template_zext_i32_to_i64(i32)

declare i32 @cq_template_mul_i64(i32, i32)

declare i32 @cq_template_trunc_i64_to_i32(i32)

declare i32 @cqrt_measure_i32(i32)

declare void @cq_template_mul_i64_unc(i32, i32, i32)

declare void @cq_template_zext_i32_to_i64_unc(i32, i32)

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #1 = { nounwind willreturn memory(none) }
