; ModuleID = '/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-r9e5/review_b1_r2_probes/out/POST/c01_mixed_tree_post_rail_theta.s1.ll'
source_filename = "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-r9e5/review_b1_r2_probes/out/POST/c01_mixed_tree_post_rail_theta.s1.ll"

define i32 @main() {
entry:
  %h = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_ry_i1(i32 %h, double 5.000000e-01)
  %h2 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_ry_i32(i32 %h2, double 2.000000e-01)
  %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h2, i32 1)
  %g = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_toffoli(i32 %h, i32 %h_cmp, i32 %g)
  %out = call i32 @cqrt_alloc_i32(i32 0)
  %selop = call i32 @cqrt_alloc_i32(i32 2)
  call void @cqrt_copy_i32_controlled(i32 %g, i32 %selop, i32 %out)
  call void @cqrt_x(i32 %g)
  %selop1 = call i32 @cqrt_alloc_i32(i32 5)
  call void @cqrt_copy_i32_controlled(i32 %g, i32 %selop1, i32 %out)
  call void @cqrt_x(i32 %g)
  call void @cqrt_toffoli(i32 %h, i32 %h_cmp, i32 %g)
  call void @cqrt_free(i32 %g)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h2, i32 1)
  call void @cqrt_free(i32 %h_cmp)
  call void @cqrt_ry_i1(i32 %h, double 3.000000e-01)
  %m3 = call i1 @cqrt_measure_i1(i32 %h)
  %m4 = call i32 @cqrt_measure_i32(i32 %out)
  ret i32 %m4
}

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_copy_i32_controlled(i32, i32, i32)

declare i32 @cqrt_alloc_i1(i1)

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

declare void @cqrt_toffoli(i32, i32, i32)

declare void @cqrt_x(i32)

declare void @cqrt_free(i32)

declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

declare void @cqrt_ry_i1(i32, double)

declare void @cqrt_ry_i32(i32, double)

declare i1 @cqrt_measure_i1(i32)

declare i32 @cqrt_measure_i32(i32)
