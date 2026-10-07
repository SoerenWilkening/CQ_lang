; ModuleID = '/tmp/p3kd78-review-r4/p2_grown_mask.ll'
source_filename = "/tmp/p3kd78-review-r4/p2_grown_mask.ll"

; Function Attrs: nounwind willreturn memory(none)
define i32 @arm_bias(i32 noundef %k) #0 {
entry:
  %r = add i32 %k, 9
  ret i32 %r
}

define i32 @finish_pair(i32 noundef %v) {
entry:
  %r = xor i32 %v, 682
  ret i32 %r
}

define i32 @growing_helper(i32 noundef %a, i32 noundef %b) {
entry:
  %lo = icmp slt i32 %a, 64
  %hi = icmp ult i32 %b, 11
  %cond = and i1 %lo, %hi
  %mix = xor i32 %a, %b
  %picked = select i1 %cond, i32 %mix, i32 %b
  %r = call i32 @finish_pair(i32 %picked)
  ret i32 %r
}

define void @exercise_growth(i32 noundef %seed, i32 noundef %other, i32 noundef %k) {
entry:
  %h = call i32 @cqrt_alloc_i32(i32 %seed)
  call void @cqrt_ry_i32(i32 %h, double 1.250000e-01)
  %h2 = call i32 @cqrt_alloc_i32(i32 %other)
  call void @cqrt_ry_i32(i32 %h2, double 7.500000e-01)
  %biased = call i32 @arm_bias(i32 %k)
  %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 13)
  %out = call i32 @cqrt_alloc_i32(i32 0)
  %selop = call i32 @cqrt_alloc_i32(i32 %biased)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %selop, i32 %out)
  call void @cqrt_x(i32 %h_cmp)
  %selop1 = call i32 @cqrt_alloc_i32(i32 -4)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %selop1, i32 %out)
  call void @cqrt_x(i32 %h_cmp)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp, i32 %h, i32 13)
  call void @cqrt_free(i32 %h_cmp)
  %r = call i32 @__cq_q_growing_helper_11(i32 %out, i32 %h2)
  %m3 = call i32 @cqrt_measure_i32(i32 %r)
  ret void
}

declare void @cqrt_copy_i32(i32, i32)

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_copy_i32_controlled(i32, i32, i32)

declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)

declare void @cqrt_x(i32)

declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

; Function Attrs: memory(readwrite)
define internal i32 @__cq_q_growing_helper_11(i32 noundef %a, i32 noundef %b) #1 {
entry:
  %h_op = call i32 @cq_template_xor_i32(i32 %a, i32 %b)
  %h_cmp = call i32 @cq_template_icmp_slt_i32_hl(i32 %a, i32 64)
  %h_cmp1 = call i32 @cq_template_icmp_ult_i32_hl(i32 %b, i32 11)
  %g = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_toffoli(i32 %h_cmp, i32 %h_cmp1, i32 %g)
  %out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32_controlled(i32 %g, i32 %h_op, i32 %out)
  call void @cqrt_x(i32 %g)
  call void @cqrt_copy_i32_controlled(i32 %g, i32 %b, i32 %out)
  %r = call i32 @__cq_q_finish_pair_1(i32 %out)
  %cqq.out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %r, i32 %cqq.out)
  call void @__cq_q_finish_pair_1_unc(i32 %r, i32 %out)
  call void @cqrt_copy_i32_controlled(i32 %g, i32 %b, i32 %out)
  call void @cqrt_x(i32 %g)
  call void @cqrt_copy_i32_controlled(i32 %g, i32 %h_op, i32 %out)
  call void @cqrt_toffoli(i32 %h_cmp, i32 %h_cmp1, i32 %g)
  call void @cq_template_icmp_ult_i32_hl_unc(i32 %h_cmp1, i32 %b, i32 11)
  call void @cq_template_icmp_slt_i32_hl_unc(i32 %h_cmp, i32 %a, i32 64)
  call void @cq_template_xor_i32_unc(i32 %h_op, i32 %a, i32 %b)
  call void @cqrt_free(i32 %h_op)
  call void @cqrt_free(i32 %h_cmp)
  call void @cqrt_free(i32 %h_cmp1)
  call void @cqrt_free(i32 %g)
  call void @cqrt_free(i32 %out)
  call void @cqrt_free(i32 %r)
  ret i32 %cqq.out
}

declare i32 @cqrt_alloc_i1(i1)

declare i32 @cq_template_icmp_slt_i32_hl(i32, i32)

declare i32 @cq_template_icmp_ult_i32_hl(i32, i32)

declare void @cqrt_toffoli(i32, i32, i32)

declare void @cq_template_icmp_ult_i32_hl_unc(i32, i32, i32)

declare void @cq_template_icmp_slt_i32_hl_unc(i32, i32, i32)

; Function Attrs: memory(readwrite)
define internal i32 @__cq_q_finish_pair_1(i32 noundef %v) #1 {
entry:
  %h_op = call i32 @cq_template_xor_i32_hl(i32 %v, i32 682)
  %cqq.out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %h_op, i32 %cqq.out)
  call void @cq_template_xor_i32_hl_unc(i32 %h_op, i32 %v, i32 682)
  call void @cqrt_free(i32 %h_op)
  ret i32 %cqq.out
}

declare i32 @cq_template_xor_i32_hl(i32, i32)

declare void @cq_template_xor_i32_hl_unc(i32, i32, i32)

; Function Attrs: memory(readwrite)
define internal void @__cq_q_finish_pair_1_unc(i32 %out, i32 noundef %v) #1 {
entry:
  %h_op = call i32 @cq_template_xor_i32_hl(i32 %v, i32 682)
  call void @cqrt_copy_i32(i32 %h_op, i32 %out)
  call void @cq_template_xor_i32_hl_unc(i32 %h_op, i32 %v, i32 682)
  call void @cqrt_free(i32 %h_op)
  ret void
}

declare i32 @cq_template_xor_i32(i32, i32)

declare void @cq_template_xor_i32_unc(i32, i32, i32)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_measure_i32(i32)

attributes #0 = { nounwind willreturn memory(none) }
attributes #1 = { memory(readwrite) }
