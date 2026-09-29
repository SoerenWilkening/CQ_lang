; ModuleID = 'ir-pass/test/lowering_live_record_sibling_clone_arg_measured_accept.ll'
source_filename = "ir-pass/test/lowering_live_record_sibling_clone_arg_measured_accept.ll"

define i32 @slice(i32 %u0) {
entry:
  %h = call i32 @cqrt_alloc_i32(i32 %u0)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %h_op = call i32 @cq_template_mul_i32_hl(i32 %h, i32 2)
  %h_op1 = call i32 @cq_template_mul_i32_hl(i32 %h, i32 3)
  call void @cqrt_ry_i32(i32 %h_op, double 5.000000e-01)
  %z = call fastcc i32 @__cq_q_inner_1(i32 %h_op1)
  call void @cq_template_mul_i32_hl_unc(i32 %h_op1, i32 %h, i32 3)
  call void @cqrt_free(i32 %h_op1)
  %m2 = call i32 @cqrt_measure_i32(i32 %z)
  %m3 = call i32 @cqrt_measure_i32(i32 %h_op)
  %m4 = call i32 @cqrt_measure_i32(i32 %h)
  %a = add nsw i32 %m3, %m2
  %r = add nsw i32 %a, %m4
  ret i32 %r
}

define internal fastcc i32 @inner(i32 %x) {
  %a = mul i32 %x, 3
  ret i32 %a
}

declare void @cqrt_copy_i32(i32, i32)

; Function Attrs: memory(readwrite)
define internal fastcc i32 @__cq_q_inner_1(i32 %x) #0 {
  %h_op = call i32 @cq_template_mul_i32_hl(i32 %x, i32 3)
  %cqq.out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %h_op, i32 %cqq.out)
  call void @cq_template_mul_i32_hl_unc(i32 %h_op, i32 %x, i32 3)
  call void @cqrt_free(i32 %h_op)
  ret i32 %cqq.out
}

declare i32 @cq_template_mul_i32_hl(i32, i32)

declare i32 @cqrt_alloc_i32(i32)

declare void @cq_template_mul_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_measure_i32(i32)

attributes #0 = { memory(readwrite) }
