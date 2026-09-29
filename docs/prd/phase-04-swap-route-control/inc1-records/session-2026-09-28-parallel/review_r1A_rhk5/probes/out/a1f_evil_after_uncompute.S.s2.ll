; ModuleID = 'a1f_evil_after_uncompute.ll'
source_filename = "a1f_evil_after_uncompute.ll"

define i32 @slice(i32 %m) {
entry:
  %a = and i32 %m, 7
  %h = call i32 @cqrt_alloc_i32(i32 %a)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %h_op = call i32 @cq_template_mul_i32_hl(i32 %h, i32 3)
  %h_op1 = call i32 @cq_template_xor_i32(i32 %h, i32 %h_op)
  %s = call i32 @__cq_q_h_10(i32 0, i32 %h)
  %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op1, i32 10)
  call void @cqrt_rz_i1(i32 %h_cmp, double 3.141590e+00), !cq.branchphase !0
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h_op1, i32 10)
  call void @cq_template_xor_i32_unc(i32 %h_op1, i32 %h, i32 %h_op)
  call void @cqrt_free(i32 %h_op1)
  call void @cq_template_mul_i32_hl_unc(i32 %h_op, i32 %h, i32 3)
  call void @cqrt_free(i32 %h_op)
  call void @cqrt_free(i32 %h_cmp)
  %m2 = call i32 @cqrt_measure_i32(i32 %s)
  call void @cqrt_ry_i32(i32 %h, double 0x3FE6666666666666)
  %m3 = call i32 @cqrt_measure_i32(i32 %h)
  %r = add nsw i32 %m3, %m2
  ret i32 %r
}

; Function Attrs: noinline
define i32 @g(i32 %k) #0 {
  %r = mul nsw i32 %k, 5
  ret i32 %r
}

define i32 @h(i32 %a, i32 %k) {
  %t = call i32 @g(i32 %k)
  %r = add nsw i32 %t, 1
  ret i32 %r
}

declare void @cqrt_x(i32)

declare void @cqrt_copy_i32(i32, i32)

declare i32 @cq_template_mul_i32_hl(i32, i32)

declare void @cq_template_mul_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

define internal void @__cq_q_g_1_unc(i32 %out, i32 %k) {
  %h_op = call i32 @cq_template_mul_i32_hl(i32 %k, i32 5)
  call void @cqrt_copy_i32(i32 %h_op, i32 %out)
  call void @cq_template_mul_i32_hl_unc(i32 %h_op, i32 %k, i32 5)
  call void @cqrt_free(i32 %h_op)
  %ev = call i32 @cq_template_evil_i32(i32 %k)
  ret void
}

; Function Attrs: noinline
define i32 @cq_template_evil_i32(i32 %x) #0 {
  call void @cqrt_x(i32 %x)
  ret i32 0
}

declare void @cqrt_rz_i1(i32, double)

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

; Function Attrs: memory(readwrite)
define internal i32 @__cq_q_h_10(i32 %a, i32 %k) #1 {
  %t = call i32 @__cq_q_g_1(i32 %k)
  %h_op = call i32 @cq_template_add_i32_hl(i32 %t, i32 1)
  %cqq.out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %h_op, i32 %cqq.out)
  call void @cq_template_add_i32_hl_unc(i32 %h_op, i32 %t, i32 1)
  call void @__cq_q_g_1_unc(i32 %t, i32 %k)
  call void @cqrt_free(i32 %t)
  call void @cqrt_free(i32 %h_op)
  ret i32 %cqq.out
}

; Function Attrs: noinline memory(readwrite)
define internal i32 @__cq_q_g_1(i32 %k) #2 {
  %h_op = call i32 @cq_template_mul_i32_hl(i32 %k, i32 5)
  %cqq.out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %h_op, i32 %cqq.out)
  call void @cq_template_mul_i32_hl_unc(i32 %h_op, i32 %k, i32 5)
  call void @cqrt_free(i32 %h_op)
  ret i32 %cqq.out
}

declare i32 @cqrt_alloc_i32(i32)

declare i32 @cq_template_add_i32_hl(i32, i32)

declare void @cq_template_add_i32_hl_unc(i32, i32, i32)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cq_template_xor_i32(i32, i32)

declare i32 @cqrt_measure_i32(i32)

declare void @cq_template_xor_i32_unc(i32, i32, i32)

attributes #0 = { noinline }
attributes #1 = { memory(readwrite) }
attributes #2 = { noinline memory(readwrite) }

!0 = !{}
