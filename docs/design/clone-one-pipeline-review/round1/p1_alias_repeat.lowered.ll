; ModuleID = '/tmp/p3kd78-review-r1/p1_alias_repeat.ll'
source_filename = "/tmp/p3kd78-review-r1/p1_alias_repeat.ll"
target triple = "x86_64-unknown-linux-gnu"

define internal i32 @calc(i32 noundef %a, i32 noundef %b) {
entry:
  %ca = icmp slt i32 %a, 17
  %cb = icmp ne i32 %b, 0
  %c = and i1 %ca, %cb
  %t = add i32 %a, 6
  %f = xor i32 %b, 29
  %v = select i1 %c, i32 %t, i32 %f
  %d = icmp eq i32 %a, 12
  %u = select i1 %d, i32 %v, i32 %b
  %r = add i32 %u, %a
  ret i32 %r
}

define i32 @probe(i32 %x) {
  %h = call i32 @cqrt_alloc_i32(i32 %x)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %r = call i32 @__cq_q_calc_11(i32 %h, i32 %h)
  %m1 = call i32 @cqrt_measure_i32(i32 %r)
  ret i32 %m1
}

declare void @cqrt_copy_i32(i32, i32)

; Function Attrs: memory(readwrite)
define internal i32 @__cq_q_calc_11(i32 noundef %a, i32 noundef %b) #0 {
entry:
  %h_op = call i32 @cq_template_add_i32_hl(i32 %a, i32 6)
  %h_op4 = call i32 @cq_template_xor_i32_hl(i32 %b, i32 29)
  %h_cmp = call i32 @cq_template_icmp_slt_i32_hl(i32 %a, i32 17)
  %h_cmp1 = call i32 @cq_template_icmp_ne_i32_hl(i32 %b, i32 0)
  %g = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_toffoli(i32 %h_cmp, i32 %h_cmp1, i32 %g)
  %out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32_controlled(i32 %g, i32 %h_op, i32 %out)
  call void @cqrt_x(i32 %g)
  call void @cqrt_copy_i32_controlled(i32 %g, i32 %h_op4, i32 %out)
  %h_cmp2 = call i32 @cq_template_icmp_eq_i32_hl(i32 %a, i32 12)
  %out3 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp2, i32 %out, i32 %out3)
  call void @cqrt_x(i32 %h_cmp2)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp2, i32 %b, i32 %out3)
  %h_op5 = call i32 @cq_template_add_i32(i32 %out3, i32 %a)
  %cqq.out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %h_op5, i32 %cqq.out)
  call void @cq_template_add_i32_unc(i32 %h_op5, i32 %out3, i32 %a)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp2, i32 %b, i32 %out3)
  call void @cqrt_x(i32 %h_cmp2)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp2, i32 %out, i32 %out3)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp2, i32 %a, i32 12)
  call void @cqrt_copy_i32_controlled(i32 %g, i32 %h_op4, i32 %out)
  call void @cqrt_x(i32 %g)
  call void @cqrt_copy_i32_controlled(i32 %g, i32 %h_op, i32 %out)
  call void @cqrt_toffoli(i32 %h_cmp, i32 %h_cmp1, i32 %g)
  call void @cq_template_icmp_ne_i32_hl_unc(i32 %h_cmp1, i32 %b, i32 0)
  call void @cq_template_icmp_slt_i32_hl_unc(i32 %h_cmp, i32 %a, i32 17)
  call void @cq_template_xor_i32_hl_unc(i32 %h_op4, i32 %b, i32 29)
  call void @cq_template_add_i32_hl_unc(i32 %h_op, i32 %a, i32 6)
  call void @cqrt_free(i32 %h_op)
  call void @cqrt_free(i32 %h_op4)
  call void @cqrt_free(i32 %h_cmp)
  call void @cqrt_free(i32 %h_cmp1)
  call void @cqrt_free(i32 %g)
  call void @cqrt_free(i32 %out)
  call void @cqrt_free(i32 %h_cmp2)
  call void @cqrt_free(i32 %out3)
  call void @cqrt_free(i32 %h_op5)
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

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

declare i32 @cq_template_add_i32_hl(i32, i32)

declare i32 @cq_template_xor_i32_hl(i32, i32)

declare i32 @cq_template_add_i32(i32, i32)

declare void @cq_template_add_i32_unc(i32, i32, i32)

declare void @cq_template_xor_i32_hl_unc(i32, i32, i32)

declare void @cq_template_add_i32_hl_unc(i32, i32, i32)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_measure_i32(i32)

attributes #0 = { memory(readwrite) }
