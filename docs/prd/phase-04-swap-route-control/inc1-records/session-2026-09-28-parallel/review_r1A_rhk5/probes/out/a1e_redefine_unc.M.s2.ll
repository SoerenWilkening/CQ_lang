; ModuleID = 'a1e_redefine_unc.ll'
source_filename = "a1e_redefine_unc.ll"

define i32 @slice(i32 %m) {
entry:
  %a = and i32 %m, 7
  %h = call i32 @cqrt_alloc_i32(i32 %a)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %h_op = call i32 @cq_template_mul_i32_hl(i32 %h, i32 3)
  %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op, i32 6)
  call void @cqrt_rz_i1(i32 %h_cmp, double 3.141590e+00), !cq.branchphase !0
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h_op, i32 6)
  call void @cq_template_mul_i32_hl_unc(i32 %h_op, i32 %h, i32 3)
  call void @cqrt_free(i32 %h_op)
  call void @cqrt_free(i32 %h_cmp)
  call void @cqrt_ry_i32(i32 %h, double 0x3FE6666666666666)
  %m1 = call i32 @cqrt_measure_i32(i32 %h)
  ret i32 %m1
}

; Function Attrs: noinline
define void @cq_template_mul_i32_hl_unc(i32 %o, i32 %x, i32 %l) #0 {
  ret void
}

declare void @cqrt_rz_i1(i32, double)

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

declare void @cqrt_x(i32)

declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare i32 @cq_template_mul_i32_hl(i32, i32)

declare i32 @cqrt_measure_i32(i32)

attributes #0 = { noinline }

!0 = !{}
