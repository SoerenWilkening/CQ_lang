; ModuleID = '/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d9542657-7eae-4089-ae6b-77dc3ed77cc3/scratchpad/rev/xorfam/notcond_4.ll'
source_filename = "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d9542657-7eae-4089-ae6b-77dc3ed77cc3/scratchpad/rev/xorfam/notcond_4.ll"

define i32 @probe(i32 %u) {
entry:
  %h = call i32 @cqrt_alloc_i32(i32 %u)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 1)
  %out = call i32 @cqrt_alloc_i32(i32 0)
  %selop = call i32 @cqrt_alloc_i32(i32 5)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %selop, i32 %out)
  call void @cqrt_x(i32 %h_cmp)
  %selop1 = call i32 @cqrt_alloc_i32(i32 2)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %selop1, i32 %out)
  call void @cqrt_x(i32 %h_cmp)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp, i32 %h, i32 1)
  call void @cqrt_free(i32 %h_cmp)
  %h_cmp2 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 1)
  %out3 = call i32 @cqrt_alloc_i32(i32 0)
  %selop4 = call i32 @cqrt_alloc_i32(i32 6)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp2, i32 %selop4, i32 %out3)
  call void @cqrt_x(i32 %h_cmp2)
  %selop5 = call i32 @cqrt_alloc_i32(i32 2)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp2, i32 %selop5, i32 %out3)
  call void @cqrt_x(i32 %h_cmp2)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp2, i32 %h, i32 1)
  call void @cqrt_free(i32 %h_cmp2)
  %h_cmp6 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 1)
  %out7 = call i32 @cqrt_alloc_i32(i32 0)
  %selop8 = call i32 @cqrt_alloc_i32(i32 7)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp6, i32 %selop8, i32 %out7)
  call void @cqrt_x(i32 %h_cmp6)
  %selop9 = call i32 @cqrt_alloc_i32(i32 2)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp6, i32 %selop9, i32 %out7)
  call void @cqrt_x(i32 %h_cmp6)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp6, i32 %h, i32 1)
  call void @cqrt_free(i32 %h_cmp6)
  %h_cmp10 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 1)
  %out11 = call i32 @cqrt_alloc_i32(i32 0)
  %selop12 = call i32 @cqrt_alloc_i32(i32 8)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp10, i32 %selop12, i32 %out11)
  call void @cqrt_x(i32 %h_cmp10)
  %selop13 = call i32 @cqrt_alloc_i32(i32 2)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp10, i32 %selop13, i32 %out11)
  call void @cqrt_x(i32 %h_cmp10)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp10, i32 %h, i32 1)
  call void @cqrt_free(i32 %h_cmp10)
  br label %merge

merge:                                            ; preds = %entry
  %m = call i32 @cqrt_measure_i32(i32 %out)
  %m14 = call i32 @cqrt_measure_i32(i32 %out3)
  %m15 = call i32 @cqrt_measure_i32(i32 %out7)
  %m16 = call i32 @cqrt_measure_i32(i32 %out11)
  %m17 = call i32 @cqrt_measure_i32(i32 %h)
  %s1 = add i32 %m, %m14
  %s2 = add i32 %s1, %m15
  %s3 = add i32 %s2, %m16
  %s4 = add i32 %s3, %m17
  ret i32 %s4
}

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_copy_i32_controlled(i32, i32, i32)

declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)

declare void @cqrt_x(i32)

declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_measure_i32(i32)
