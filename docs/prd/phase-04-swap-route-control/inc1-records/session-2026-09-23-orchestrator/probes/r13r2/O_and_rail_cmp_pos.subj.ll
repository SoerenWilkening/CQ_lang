; ModuleID = 'O_and_rail_cmp_pos.ll'
source_filename = "O_and_rail_cmp_pos.ll"

define i32 @probe(i32 %u) {
entry:
  %h = call i32 @cqrt_alloc_i32(i32 %u)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %h7 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_ry_i1(i32 %h7, double 5.000000e-01)
  %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 1)
  %g = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_toffoli(i32 %h7, i32 %h_cmp, i32 %g)
  %out = call i32 @cqrt_alloc_i32(i32 0)
  %selop = call i32 @cqrt_alloc_i32(i32 2)
  call void @cqrt_copy_i32_controlled(i32 %g, i32 %selop, i32 %out)
  call void @cqrt_x(i32 %g)
  %selop1 = call i32 @cqrt_alloc_i32(i32 5)
  call void @cqrt_copy_i32_controlled(i32 %g, i32 %selop1, i32 %out)
  call void @cqrt_x(i32 %g)
  call void @cqrt_toffoli(i32 %h7, i32 %h_cmp, i32 %g)
  call void @cqrt_free(i32 %g)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp, i32 %h, i32 1)
  call void @cqrt_free(i32 %h_cmp)
  %h_cmp2 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 1)
  %g3 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_toffoli(i32 %h7, i32 %h_cmp2, i32 %g3)
  %out4 = call i32 @cqrt_alloc_i32(i32 0)
  %selop5 = call i32 @cqrt_alloc_i32(i32 3)
  call void @cqrt_copy_i32_controlled(i32 %g3, i32 %selop5, i32 %out4)
  call void @cqrt_x(i32 %g3)
  %selop6 = call i32 @cqrt_alloc_i32(i32 6)
  call void @cqrt_copy_i32_controlled(i32 %g3, i32 %selop6, i32 %out4)
  call void @cqrt_x(i32 %g3)
  call void @cqrt_toffoli(i32 %h7, i32 %h_cmp2, i32 %g3)
  call void @cqrt_free(i32 %g3)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp2, i32 %h, i32 1)
  call void @cqrt_free(i32 %h_cmp2)
  br label %merge

merge:                                            ; preds = %entry
  %m = call i32 @cqrt_measure_i32(i32 %out)
  %m8 = call i32 @cqrt_measure_i32(i32 %out4)
  %m9 = call i32 @cqrt_measure_i32(i32 %h)
  %m10 = call i1 @cqrt_measure_i1(i32 %h7)
  %z = zext i1 %m10 to i32
  %s = add i32 %m, %m8
  %s2 = add i32 %s, %m9
  %s3 = add i32 %s2, %z
  ret i32 %s3
}

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_copy_i32_controlled(i32, i32, i32)

declare i32 @cqrt_alloc_i1(i1)

declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)

declare void @cqrt_toffoli(i32, i32, i32)

declare void @cqrt_x(i32)

declare void @cqrt_free(i32)

declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)

declare void @cqrt_ry_i32(i32, double)

declare void @cqrt_ry_i1(i32, double)

declare i32 @cqrt_measure_i32(i32)

declare i1 @cqrt_measure_i1(i32)
