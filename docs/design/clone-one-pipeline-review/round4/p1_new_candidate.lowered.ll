; ModuleID = '/tmp/p3kd78-review-r4/p1_new_candidate.ll'
source_filename = "/tmp/p3kd78-review-r4/p1_new_candidate.ll"

; Function Attrs: nounwind willreturn memory(none)
define i32 @arm_scramble(i32 noundef %k) #0 {
entry:
  %r = xor i32 %k, 90
  ret i32 %r
}

define i32 @finish_value(i32 noundef %v) {
entry:
  %scaled = mul i32 %v, 5
  %r = add i32 %scaled, 2
  ret i32 %r
}

define i32 @new_helper(i32 noundef %v) {
entry:
  %lo = icmp sgt i32 %v, -11
  %hi = icmp ult i32 %v, 37
  %cond = and i1 %lo, %hi
  %flip = xor i32 %v, 255
  %picked = select i1 %cond, i32 %flip, i32 %v
  %r = call i32 @finish_value(i32 %picked)
  ret i32 %r
}

define void @exercise_new(i32 noundef %seed, i32 noundef %k) {
entry:
  %h = call i32 @cqrt_alloc_i32(i32 %seed)
  call void @cqrt_ry_i32(i32 %h, double 3.750000e-01)
  %scrambled = call i32 @arm_scramble(i32 %k)
  %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 7)
  %out = call i32 @cqrt_alloc_i32(i32 0)
  %selop = call i32 @cqrt_alloc_i32(i32 %scrambled)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %selop, i32 %out)
  call void @cqrt_x(i32 %h_cmp)
  %selop1 = call i32 @cqrt_alloc_i32(i32 17)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %selop1, i32 %out)
  call void @cqrt_x(i32 %h_cmp)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp, i32 %h, i32 7)
  call void @cqrt_free(i32 %h_cmp)
  %r = call i32 @__cq_q_new_helper_1(i32 %out)
  %m2 = call i32 @cqrt_measure_i32(i32 %r)
  ret void
}

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_copy_i32_controlled(i32, i32, i32)

declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)

declare void @cqrt_x(i32)

declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cqrt_copy_i32(i32, i32)

; Function Attrs: memory(readwrite)
define internal i32 @__cq_q_new_helper_1(i32 noundef %v) #1 {
entry:
  %h_op = call i32 @cq_template_xor_i32_hl(i32 %v, i32 255)
  %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %v, i32 -11)
  %h_cmp1 = call i32 @cq_template_icmp_ult_i32_hl(i32 %v, i32 37)
  %g = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_toffoli(i32 %h_cmp, i32 %h_cmp1, i32 %g)
  %out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32_controlled(i32 %g, i32 %h_op, i32 %out)
  call void @cqrt_x(i32 %g)
  call void @cqrt_copy_i32_controlled(i32 %g, i32 %v, i32 %out)
  %r = call i32 @__cq_q_finish_value_1(i32 %out)
  %cqq.out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %r, i32 %cqq.out)
  call void @__cq_q_finish_value_1_unc(i32 %r, i32 %out)
  call void @cqrt_copy_i32_controlled(i32 %g, i32 %v, i32 %out)
  call void @cqrt_x(i32 %g)
  call void @cqrt_copy_i32_controlled(i32 %g, i32 %h_op, i32 %out)
  call void @cqrt_toffoli(i32 %h_cmp, i32 %h_cmp1, i32 %g)
  call void @cq_template_icmp_ult_i32_hl_unc(i32 %h_cmp1, i32 %v, i32 37)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp, i32 %v, i32 -11)
  call void @cq_template_xor_i32_hl_unc(i32 %h_op, i32 %v, i32 255)
  call void @cqrt_free(i32 %h_op)
  call void @cqrt_free(i32 %h_cmp)
  call void @cqrt_free(i32 %h_cmp1)
  call void @cqrt_free(i32 %g)
  call void @cqrt_free(i32 %out)
  call void @cqrt_free(i32 %r)
  ret i32 %cqq.out
}

declare i32 @cqrt_alloc_i1(i1)

declare i32 @cq_template_icmp_ult_i32_hl(i32, i32)

declare void @cqrt_toffoli(i32, i32, i32)

declare void @cq_template_icmp_ult_i32_hl_unc(i32, i32, i32)

; Function Attrs: memory(readwrite)
define internal i32 @__cq_q_finish_value_1(i32 noundef %v) #1 {
entry:
  %h_op = call i32 @cq_template_mul_i32_hl(i32 %v, i32 5)
  %h_op1 = call i32 @cq_template_add_i32_hl(i32 %h_op, i32 2)
  %cqq.out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %h_op1, i32 %cqq.out)
  call void @cq_template_add_i32_hl_unc(i32 %h_op1, i32 %h_op, i32 2)
  call void @cq_template_mul_i32_hl_unc(i32 %h_op, i32 %v, i32 5)
  call void @cqrt_free(i32 %h_op)
  call void @cqrt_free(i32 %h_op1)
  ret i32 %cqq.out
}

declare i32 @cq_template_mul_i32_hl(i32, i32)

declare i32 @cq_template_add_i32_hl(i32, i32)

declare void @cq_template_add_i32_hl_unc(i32, i32, i32)

declare void @cq_template_mul_i32_hl_unc(i32, i32, i32)

; Function Attrs: memory(readwrite)
define internal void @__cq_q_finish_value_1_unc(i32 %out, i32 noundef %v) #1 {
entry:
  %h_op = call i32 @cq_template_mul_i32_hl(i32 %v, i32 5)
  %h_op1 = call i32 @cq_template_add_i32_hl(i32 %h_op, i32 2)
  call void @cqrt_copy_i32(i32 %h_op1, i32 %out)
  call void @cq_template_add_i32_hl_unc(i32 %h_op1, i32 %h_op, i32 2)
  call void @cq_template_mul_i32_hl_unc(i32 %h_op, i32 %v, i32 5)
  call void @cqrt_free(i32 %h_op)
  call void @cqrt_free(i32 %h_op1)
  ret void
}

declare i32 @cq_template_xor_i32_hl(i32, i32)

declare void @cq_template_xor_i32_hl_unc(i32, i32, i32)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_measure_i32(i32)

attributes #0 = { nounwind willreturn memory(none) }
attributes #1 = { memory(readwrite) }
