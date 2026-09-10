; ModuleID = '/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-r9e5/review_b1_r2_probes/out/POST/e14_rail_select_arm_is_out.s1.ll'
source_filename = "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-r9e5/review_b1_r2_probes/out/POST/e14_rail_select_arm_is_out.s1.ll"

; Function Attrs: nounwind willreturn memory(none)
define i32 @f(i32 %a) #0 {
  %s = add i32 %a, 100
  ret i32 %s
}

define i32 @main() {
entry:
  %h = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %r = call i32 @f(i32 4)
  %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 3)
  %out = call i32 @cqrt_alloc_i32(i32 0)
  %selop = call i32 @cqrt_alloc_i32(i32 %r)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %selop, i32 %out)
  call void @cqrt_x(i32 %h_cmp)
  %selop1 = call i32 @cqrt_alloc_i32(i32 5)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %selop1, i32 %out)
  call void @cqrt_x(i32 %h_cmp)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp, i32 %h, i32 3)
  call void @cqrt_free(i32 %h_cmp)
  %h4 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_ry_i1(i32 %h4, double 2.500000e-01)
  %bf = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_cnot(i32 %h4, i32 %bf)
  %out2 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32_controlled(i32 %bf, i32 %out, i32 %out2)
  call void @cqrt_x(i32 %bf)
  %selop3 = call i32 @cqrt_alloc_i32(i32 99)
  call void @cqrt_copy_i32_controlled(i32 %bf, i32 %selop3, i32 %out2)
  call void @cqrt_x(i32 %bf)
  call void @cqrt_cnot(i32 %h4, i32 %bf)
  call void @cqrt_free(i32 %bf)
  %m5 = call i32 @cqrt_measure_i32(i32 %out2)
  ret i32 %m5
}

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_copy_i32_controlled(i32, i32, i32)

declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)

declare void @cqrt_x(i32)

declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_cnot(i32, i32)

declare void @cqrt_ry_i32(i32, double)

declare void @cqrt_ry_i1(i32, double)

declare i32 @cqrt_measure_i32(i32)

attributes #0 = { nounwind willreturn memory(none) }
