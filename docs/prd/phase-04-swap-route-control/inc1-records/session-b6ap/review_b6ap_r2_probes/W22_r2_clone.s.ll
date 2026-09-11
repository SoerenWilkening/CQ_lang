; ModuleID = 'W22_r2_clone.s1.ll'
source_filename = "W22_r2_clone.s1.ll"

@g_probe = global i32 0

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
  %r = call fastcc i32 @f(i32 4) #2
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
  call void @cqrt_x(i32 %h_cmp3)
  %h7 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_ry_i32_controlled(i32 %h_cmp3, i32 %h7, double 5.000000e-01)
  call void @cqrt_x(i32 %h_cmp3)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp3, i32 %out1, i32 13)
  call void @cqrt_free(i32 %h_cmp3)
  %h_cmp4 = call i32 @cq_template_icmp_eq_i32_hl(i32 %out1, i32 13)
  %out = call i32 @cqrt_alloc_i32(i32 0)
  %selop5 = call i32 @cqrt_alloc_i32(i32 2)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp4, i32 %selop5, i32 %out)
  call void @cqrt_x(i32 %h_cmp4)
  %selop6 = call i32 @cqrt_alloc_i32(i32 5)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp4, i32 %selop6, i32 %out)
  call void @cqrt_x(i32 %h_cmp4)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp4, i32 %out1, i32 13)
  call void @cqrt_free(i32 %h_cmp4)
  %ht = call fastcc i32 @__cq_q_helper_1(i32 %out)
  %m = call i32 @cqrt_measure_i32(i32 %ht)
  %m8 = call i32 @cqrt_measure_i32(i32 %h)
  %m9 = call i32 @cqrt_measure_i32(i32 %out1)
  %m10 = call i32 @cqrt_measure_i32(i32 %h7)
  %m11 = call i32 @cqrt_measure_i32(i32 %out)
  %s1 = add nsw i32 %m8, %m9
  %s2 = add nsw i32 %s1, %m10
  %s3 = add nsw i32 %s2, %m11
  ret i32 %s3
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none)
define internal fastcc i32 @helper(i32 %x) unnamed_addr #0 {
  %y = add nsw i32 %x, 1
  ret i32 %y
}

define i32 @main() {
  %r = call i32 @example()
  ret i32 0
}

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_copy_i32_controlled(i32, i32, i32)

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

declare void @cqrt_x(i32)

declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cqrt_copy_i32(i32, i32)

; Function Attrs: mustprogress noinline norecurse nosync nounwind memory(readwrite)
define internal fastcc i32 @__cq_q_helper_1(i32 %x) unnamed_addr #1 {
  %h_op = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)
  %cqq.out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %h_op, i32 %cqq.out)
  call void @cq_template_add_i32_hl_unc(i32 %h_op, i32 %x, i32 1)
  call void @cqrt_free(i32 %h_op)
  ret i32 %cqq.out
}

declare i32 @cq_template_add_i32_hl(i32, i32)

declare void @cq_template_add_i32_hl_unc(i32, i32, i32)

declare void @cqrt_ry_i32(i32, double)

declare void @cqrt_ry_i32_controlled(i32, i32, double)

declare i32 @cqrt_measure_i32(i32)

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #1 = { mustprogress noinline norecurse nosync nounwind memory(readwrite) }
attributes #2 = { nounwind willreturn memory(none) }
