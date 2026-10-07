; ModuleID = '/tmp/p3kd78-review-r3/p3_nested_networks.ll'
source_filename = "/tmp/p3kd78-review-r3/p3_nested_networks.ll"
target triple = "x86_64-unknown-linux-gnu"

define internal i32 @leaf(i32 noundef %a) {
entry:
  %c1 = icmp sgt i32 %a, 1
  %c2 = icmp slt i32 %a, 19
  %g = and i1 %c1, %c2
  %t = xor i32 %a, 41
  %f = add i32 %a, 13
  %r = select i1 %g, i32 %t, i32 %f
  ret i32 %r
}

define internal i32 @outer(i32 noundef %q) {
entry:
  %a = call i32 @leaf(i32 %q)
  %b = call i32 @leaf(i32 %a)
  %c1 = icmp slt i32 %b, 100
  %c2 = icmp ne i32 %q, 7
  %g = and i1 %c1, %c2
  %r = select i1 %g, i32 %a, i32 %b
  ret i32 %r
}

define i32 @probe(i32 %x) {
  %h = call i32 @cqrt_alloc_i32(i32 %x)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %r = call i32 @__cq_q_outer_1(i32 %h)
  %m1 = call i32 @cqrt_measure_i32(i32 %r)
  ret i32 %m1
}

declare void @cqrt_copy_i32(i32, i32)

; Function Attrs: memory(readwrite)
define internal i32 @__cq_q_outer_1(i32 noundef %q) #0 {
entry:
  %a = call i32 @__cq_q_leaf_1(i32 %q)
  %b = call i32 @__cq_q_leaf_1(i32 %a)
  %h_cmp = call i32 @cq_template_icmp_slt_i32_hl(i32 %b, i32 100)
  %h_cmp1 = call i32 @cq_template_icmp_ne_i32_hl(i32 %q, i32 7)
  %g2 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_toffoli(i32 %h_cmp, i32 %h_cmp1, i32 %g2)
  %out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32_controlled(i32 %g2, i32 %a, i32 %out)
  call void @cqrt_x(i32 %g2)
  call void @cqrt_copy_i32_controlled(i32 %g2, i32 %b, i32 %out)
  %cqq.out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %out, i32 %cqq.out)
  call void @cqrt_copy_i32_controlled(i32 %g2, i32 %b, i32 %out)
  call void @cqrt_x(i32 %g2)
  call void @cqrt_copy_i32_controlled(i32 %g2, i32 %a, i32 %out)
  call void @cqrt_toffoli(i32 %h_cmp, i32 %h_cmp1, i32 %g2)
  call void @cq_template_icmp_ne_i32_hl_unc(i32 %h_cmp1, i32 %q, i32 7)
  call void @cq_template_icmp_slt_i32_hl_unc(i32 %h_cmp, i32 %b, i32 100)
  call void @__cq_q_leaf_1_unc(i32 %b, i32 %a)
  call void @__cq_q_leaf_1_unc(i32 %a, i32 %q)
  call void @cqrt_free(i32 %a)
  call void @cqrt_free(i32 %b)
  call void @cqrt_free(i32 %h_cmp)
  call void @cqrt_free(i32 %h_cmp1)
  call void @cqrt_free(i32 %g2)
  call void @cqrt_free(i32 %out)
  ret i32 %cqq.out
}

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_copy_i32_controlled(i32, i32, i32)

declare i32 @cqrt_alloc_i1(i1)

declare i32 @cq_template_icmp_slt_i32_hl(i32, i32)

declare i32 @cq_template_icmp_ne_i32_hl(i32, i32)

declare void @cqrt_toffoli(i32, i32, i32)

declare void @cqrt_x(i32)

declare void @cqrt_free(i32)

declare void @cq_template_icmp_ne_i32_hl_unc(i32, i32, i32)

declare void @cq_template_icmp_slt_i32_hl_unc(i32, i32, i32)

; Function Attrs: memory(readwrite)
define internal i32 @__cq_q_leaf_1(i32 noundef %a) #0 {
entry:
  %h_op = call i32 @cq_template_xor_i32_hl(i32 %a, i32 41)
  %h_op3 = call i32 @cq_template_add_i32_hl(i32 %a, i32 13)
  %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %a, i32 1)
  %h_cmp1 = call i32 @cq_template_icmp_slt_i32_hl(i32 %a, i32 19)
  %g2 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_toffoli(i32 %h_cmp, i32 %h_cmp1, i32 %g2)
  %out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32_controlled(i32 %g2, i32 %h_op, i32 %out)
  call void @cqrt_x(i32 %g2)
  call void @cqrt_copy_i32_controlled(i32 %g2, i32 %h_op3, i32 %out)
  %cqq.out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %out, i32 %cqq.out)
  call void @cqrt_copy_i32_controlled(i32 %g2, i32 %h_op3, i32 %out)
  call void @cqrt_x(i32 %g2)
  call void @cqrt_copy_i32_controlled(i32 %g2, i32 %h_op, i32 %out)
  call void @cqrt_toffoli(i32 %h_cmp, i32 %h_cmp1, i32 %g2)
  call void @cq_template_icmp_slt_i32_hl_unc(i32 %h_cmp1, i32 %a, i32 19)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp, i32 %a, i32 1)
  call void @cq_template_add_i32_hl_unc(i32 %h_op3, i32 %a, i32 13)
  call void @cq_template_xor_i32_hl_unc(i32 %h_op, i32 %a, i32 41)
  call void @cqrt_free(i32 %h_op)
  call void @cqrt_free(i32 %h_op3)
  call void @cqrt_free(i32 %h_cmp)
  call void @cqrt_free(i32 %h_cmp1)
  call void @cqrt_free(i32 %g2)
  call void @cqrt_free(i32 %out)
  ret i32 %cqq.out
}

declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)

declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)

declare i32 @cq_template_xor_i32_hl(i32, i32)

declare i32 @cq_template_add_i32_hl(i32, i32)

declare void @cq_template_add_i32_hl_unc(i32, i32, i32)

declare void @cq_template_xor_i32_hl_unc(i32, i32, i32)

; Function Attrs: memory(readwrite)
define internal void @__cq_q_leaf_1_unc(i32 %out, i32 noundef %a) #0 {
entry:
  %h_op = call i32 @cq_template_xor_i32_hl(i32 %a, i32 41)
  %h_op3 = call i32 @cq_template_add_i32_hl(i32 %a, i32 13)
  %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %a, i32 1)
  %h_cmp1 = call i32 @cq_template_icmp_slt_i32_hl(i32 %a, i32 19)
  %g2 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_toffoli(i32 %h_cmp, i32 %h_cmp1, i32 %g2)
  %out1 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32_controlled(i32 %g2, i32 %h_op, i32 %out1)
  call void @cqrt_x(i32 %g2)
  call void @cqrt_copy_i32_controlled(i32 %g2, i32 %h_op3, i32 %out1)
  call void @cqrt_copy_i32(i32 %out1, i32 %out)
  call void @cqrt_copy_i32_controlled(i32 %g2, i32 %h_op3, i32 %out1)
  call void @cqrt_x(i32 %g2)
  call void @cqrt_copy_i32_controlled(i32 %g2, i32 %h_op, i32 %out1)
  call void @cqrt_toffoli(i32 %h_cmp, i32 %h_cmp1, i32 %g2)
  call void @cq_template_icmp_slt_i32_hl_unc(i32 %h_cmp1, i32 %a, i32 19)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp, i32 %a, i32 1)
  call void @cq_template_add_i32_hl_unc(i32 %h_op3, i32 %a, i32 13)
  call void @cq_template_xor_i32_hl_unc(i32 %h_op, i32 %a, i32 41)
  call void @cqrt_free(i32 %h_op)
  call void @cqrt_free(i32 %h_op3)
  call void @cqrt_free(i32 %h_cmp)
  call void @cqrt_free(i32 %h_cmp1)
  call void @cqrt_free(i32 %g2)
  call void @cqrt_free(i32 %out1)
  ret void
}

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_measure_i32(i32)

attributes #0 = { memory(readwrite) }
