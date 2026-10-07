; ModuleID = '/tmp/p3kd78-review-r3/p5_logical_select_compose.ll'
source_filename = "/tmp/p3kd78-review-r3/p5_logical_select_compose.ll"
target triple = "x86_64-unknown-linux-gnu"

define internal i32 @logical(i32 noundef %a) {
entry:
  %c1 = icmp eq i32 %a, 23
  %c2 = icmp slt i32 %a, 4
  %c3 = icmp ne i32 %a, 1
  %o = select i1 %c1, i1 true, i1 %c2
  %g = select i1 %o, i1 %c3, i1 false
  br i1 %g, label %yes, label %no

yes:                                              ; preds = %entry
  %t = add i32 %a, 3
  br label %exit

no:                                               ; preds = %entry
  %f = xor i32 %a, 17
  br label %exit

exit:                                             ; preds = %no, %yes
  %r = phi i32 [ %t, %yes ], [ %f, %no ]
  ret i32 %r
}

define i32 @probe(i32 %x) {
  %h = call i32 @cqrt_alloc_i32(i32 %x)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %r = call i32 @__cq_q_logical_1(i32 %h)
  %m1 = call i32 @cqrt_measure_i32(i32 %r)
  ret i32 %m1
}

declare void @cqrt_copy_i32(i32, i32)

; Function Attrs: memory(readwrite)
define internal i32 @__cq_q_logical_1(i32 noundef %a) #0 {
entry:
  %h_op = call i32 @cq_template_xor_i32_hl(i32 %a, i32 17)
  %h_op4 = call i32 @cq_template_add_i32_hl(i32 %a, i32 3)
  %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %a, i32 23)
  %h_cmp1 = call i32 @cq_template_icmp_slt_i32_hl(i32 %a, i32 4)
  %g = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_cnot(i32 %h_cmp, i32 %g)
  call void @cqrt_cnot(i32 %h_cmp1, i32 %g)
  call void @cqrt_toffoli(i32 %h_cmp, i32 %h_cmp1, i32 %g)
  %h_cmp2 = call i32 @cq_template_icmp_ne_i32_hl(i32 %a, i32 1)
  %g3 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_toffoli(i32 %g, i32 %h_cmp2, i32 %g3)
  %out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32_controlled(i32 %g3, i32 %h_op4, i32 %out)
  call void @cqrt_x(i32 %g3)
  call void @cqrt_copy_i32_controlled(i32 %g3, i32 %h_op, i32 %out)
  %cqq.out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %out, i32 %cqq.out)
  call void @cqrt_copy_i32_controlled(i32 %g3, i32 %h_op, i32 %out)
  call void @cqrt_x(i32 %g3)
  call void @cqrt_copy_i32_controlled(i32 %g3, i32 %h_op4, i32 %out)
  call void @cqrt_toffoli(i32 %g, i32 %h_cmp2, i32 %g3)
  call void @cq_template_icmp_ne_i32_hl_unc(i32 %h_cmp2, i32 %a, i32 1)
  call void @cqrt_toffoli(i32 %h_cmp, i32 %h_cmp1, i32 %g)
  call void @cqrt_cnot(i32 %h_cmp1, i32 %g)
  call void @cqrt_cnot(i32 %h_cmp, i32 %g)
  call void @cq_template_icmp_slt_i32_hl_unc(i32 %h_cmp1, i32 %a, i32 4)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %a, i32 23)
  call void @cq_template_add_i32_hl_unc(i32 %h_op4, i32 %a, i32 3)
  call void @cq_template_xor_i32_hl_unc(i32 %h_op, i32 %a, i32 17)
  call void @cqrt_free(i32 %h_op)
  call void @cqrt_free(i32 %h_op4)
  call void @cqrt_free(i32 %h_cmp)
  call void @cqrt_free(i32 %h_cmp1)
  call void @cqrt_free(i32 %g)
  call void @cqrt_free(i32 %h_cmp2)
  call void @cqrt_free(i32 %g3)
  call void @cqrt_free(i32 %out)
  ret i32 %cqq.out
}

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_copy_i32_controlled(i32, i32, i32)

declare i32 @cqrt_alloc_i1(i1)

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

declare i32 @cq_template_icmp_slt_i32_hl(i32, i32)

declare void @cqrt_cnot(i32, i32)

declare void @cqrt_toffoli(i32, i32, i32)

declare i32 @cq_template_icmp_ne_i32_hl(i32, i32)

declare void @cqrt_x(i32)

declare void @cqrt_free(i32)

declare void @cq_template_icmp_ne_i32_hl_unc(i32, i32, i32)

declare void @cq_template_icmp_slt_i32_hl_unc(i32, i32, i32)

declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

declare i32 @cq_template_xor_i32_hl(i32, i32)

declare i32 @cq_template_add_i32_hl(i32, i32)

declare void @cq_template_add_i32_hl_unc(i32, i32, i32)

declare void @cq_template_xor_i32_hl_unc(i32, i32, i32)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_measure_i32(i32)

attributes #0 = { memory(readwrite) }
