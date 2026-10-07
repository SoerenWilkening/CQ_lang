; ModuleID = '/tmp/p3kd78-review-r3/p4_condition_late_reads.ll'
source_filename = "/tmp/p3kd78-review-r3/p4_condition_late_reads.ll"
target triple = "x86_64-unknown-linux-gnu"

define internal i32 @conddata(i32 noundef %a) {
entry:
  %c1 = icmp sgt i32 %a, 3
  %c2 = icmp slt i32 %a, 88
  %g = and i1 %c1, %c2
  %t = xor i32 %a, 7
  %f = add i32 %a, 2
  %v = select i1 %g, i32 %t, i32 %f
  %gi = zext i1 %g to i32
  %ci = zext i1 %c1 to i32
  %v1 = add i32 %v, %gi
  %r = add i32 %v1, %ci
  ret i32 %r
}

define i32 @probe(i32 %x) {
  %h = call i32 @cqrt_alloc_i32(i32 %x)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %r = call i32 @__cq_q_conddata_1(i32 %h)
  %m1 = call i32 @cqrt_measure_i32(i32 %r)
  ret i32 %m1
}

declare void @cqrt_copy_i32(i32, i32)

; Function Attrs: memory(readwrite)
define internal i32 @__cq_q_conddata_1(i32 noundef %a) #0 {
entry:
  %h_cmp3 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %a, i32 3)
  %h_cmp4 = call i32 @cq_template_icmp_slt_i32_hl(i32 %a, i32 88)
  %h_op = call i32 @cq_template_and_i1(i32 %h_cmp3, i32 %h_cmp4)
  %h_op5 = call i32 @cq_template_xor_i32_hl(i32 %a, i32 7)
  %h_op6 = call i32 @cq_template_add_i32_hl(i32 %a, i32 2)
  %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %a, i32 3)
  %h_cmp1 = call i32 @cq_template_icmp_slt_i32_hl(i32 %a, i32 88)
  %g2 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_toffoli(i32 %h_cmp, i32 %h_cmp1, i32 %g2)
  %out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32_controlled(i32 %g2, i32 %h_op5, i32 %out)
  call void @cqrt_x(i32 %g2)
  call void @cqrt_copy_i32_controlled(i32 %g2, i32 %h_op6, i32 %out)
  %h_cast = call i32 @cq_template_zext_i1_to_i32(i32 %h_op)
  %h_cast7 = call i32 @cq_template_zext_i1_to_i32(i32 %h_cmp3)
  %h_op8 = call i32 @cq_template_add_i32(i32 %out, i32 %h_cast)
  %h_op9 = call i32 @cq_template_add_i32(i32 %h_cast7, i32 %h_op8)
  %cqq.out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %h_op9, i32 %cqq.out)
  call void @cq_template_add_i32_unc(i32 %h_op9, i32 %h_cast7, i32 %h_op8)
  call void @cq_template_add_i32_unc(i32 %h_op8, i32 %out, i32 %h_cast)
  call void @cq_template_zext_i1_to_i32_unc(i32 %h_cast7, i32 %h_cmp3)
  call void @cq_template_zext_i1_to_i32_unc(i32 %h_cast, i32 %h_op)
  call void @cqrt_copy_i32_controlled(i32 %g2, i32 %h_op6, i32 %out)
  call void @cqrt_x(i32 %g2)
  call void @cqrt_copy_i32_controlled(i32 %g2, i32 %h_op5, i32 %out)
  call void @cqrt_toffoli(i32 %h_cmp, i32 %h_cmp1, i32 %g2)
  call void @cq_template_icmp_slt_i32_hl_unc(i32 %h_cmp1, i32 %a, i32 88)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp, i32 %a, i32 3)
  call void @cq_template_add_i32_hl_unc(i32 %h_op6, i32 %a, i32 2)
  call void @cq_template_xor_i32_hl_unc(i32 %h_op5, i32 %a, i32 7)
  call void @cq_template_and_i1_unc(i32 %h_op, i32 %h_cmp3, i32 %h_cmp4)
  call void @cq_template_icmp_slt_i32_hl_unc(i32 %h_cmp4, i32 %a, i32 88)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp3, i32 %a, i32 3)
  call void @cqrt_free(i32 %h_cmp3)
  call void @cqrt_free(i32 %h_cmp4)
  call void @cqrt_free(i32 %h_op)
  call void @cqrt_free(i32 %h_op5)
  call void @cqrt_free(i32 %h_op6)
  call void @cqrt_free(i32 %h_cmp)
  call void @cqrt_free(i32 %h_cmp1)
  call void @cqrt_free(i32 %g2)
  call void @cqrt_free(i32 %out)
  call void @cqrt_free(i32 %h_cast)
  call void @cqrt_free(i32 %h_cast7)
  call void @cqrt_free(i32 %h_op8)
  call void @cqrt_free(i32 %h_op9)
  ret i32 %cqq.out
}

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_copy_i32_controlled(i32, i32, i32)

declare i32 @cqrt_alloc_i1(i1)

declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)

declare i32 @cq_template_icmp_slt_i32_hl(i32, i32)

declare void @cqrt_toffoli(i32, i32, i32)

declare void @cqrt_x(i32)

declare void @cqrt_free(i32)

declare void @cq_template_icmp_slt_i32_hl_unc(i32, i32, i32)

declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)

declare i32 @cq_template_and_i1(i32, i32)

declare i32 @cq_template_xor_i32_hl(i32, i32)

declare i32 @cq_template_add_i32_hl(i32, i32)

declare i32 @cq_template_zext_i1_to_i32(i32)

declare i32 @cq_template_add_i32(i32, i32)

declare void @cq_template_add_i32_unc(i32, i32, i32)

declare void @cq_template_zext_i1_to_i32_unc(i32, i32)

declare void @cq_template_add_i32_hl_unc(i32, i32, i32)

declare void @cq_template_xor_i32_hl_unc(i32, i32, i32)

declare void @cq_template_and_i1_unc(i32, i32, i32)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_measure_i32(i32)

attributes #0 = { memory(readwrite) }
