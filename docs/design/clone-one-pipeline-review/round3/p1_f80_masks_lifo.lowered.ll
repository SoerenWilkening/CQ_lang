; ModuleID = '/tmp/p3kd78-review-r3/p1_f80_masks_lifo.ll'
source_filename = "/tmp/p3kd78-review-r3/p1_f80_masks_lifo.ll"
target triple = "x86_64-unknown-linux-gnu"

define internal i32 @mix(x86_fp80 noundef %x, i32 noundef %i, double noundef %c) {
entry:
  %if = sitofp i32 %i to x86_fp80
  %cf = fpext double %c to x86_fp80
  %a = fadd x86_fp80 %x, %if
  %b = fsub x86_fp80 %x, %cf
  %c1 = fcmp olt x86_fp80 %a, %cf
  %c2 = icmp ne i32 %i, 0
  %g = and i1 %c1, %c2
  %r = select i1 %g, x86_fp80 %a, x86_fp80 %b
  %n = fptosi x86_fp80 %r to i32
  ret i32 %n
}

define i32 @probe(x86_fp80 %x, i32 %i, double %c) {
  %h = call i32 @cqrt_alloc_f80(x86_fp80 %x)
  call void @cqrt_ry_f80(i32 %h, double 5.000000e-01)
  %h1 = call i32 @cqrt_alloc_i32(i32 %i)
  call void @cqrt_ry_i32(i32 %h1, double 7.500000e-01)
  %r = call i32 @__cq_q_mix_011(i32 %h, i32 %h1, double %c)
  %m2 = call i32 @cqrt_measure_i32(i32 %r)
  ret i32 %m2
}

declare void @cqrt_copy_i32(i32, i32)

; Function Attrs: memory(readwrite)
define internal i32 @__cq_q_mix_011(i32 %x, i32 noundef %i, double noundef %c) #0 {
entry:
  %h_cast = call i32 @cq_template_sitofp_i32_to_f80(i32 %i)
  %cf = fpext double %c to x86_fp80
  %h_op = call i32 @cq_template_fadd_f80(i32 %x, i32 %h_cast)
  %h_op1 = call i32 @cq_template_fsub_f80_hl(i32 %x, x86_fp80 %cf)
  %h_cmp = call i32 @cq_template_fcmp_olt_f80_hl(i32 %h_op, x86_fp80 %cf)
  %h_cmp1 = call i32 @cq_template_icmp_ne_i32_hl(i32 %i, i32 0)
  %g2 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_toffoli(i32 %h_cmp, i32 %h_cmp1, i32 %g2)
  %out = call i32 @cqrt_alloc_f80(x86_fp80 0xK00000000000000000000)
  call void @cqrt_copy_f80_controlled(i32 %g2, i32 %h_op, i32 %out)
  call void @cqrt_x(i32 %g2)
  call void @cqrt_copy_f80_controlled(i32 %g2, i32 %h_op1, i32 %out)
  %h_cast2 = call i32 @cq_template_fptosi_f80_to_i32(i32 %out)
  %cqq.out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %h_cast2, i32 %cqq.out)
  call void @cq_template_fptosi_f80_to_i32_unc(i32 %h_cast2, i32 %out)
  call void @cqrt_copy_f80_controlled(i32 %g2, i32 %h_op1, i32 %out)
  call void @cqrt_x(i32 %g2)
  call void @cqrt_copy_f80_controlled(i32 %g2, i32 %h_op, i32 %out)
  call void @cqrt_toffoli(i32 %h_cmp, i32 %h_cmp1, i32 %g2)
  call void @cq_template_icmp_ne_i32_hl_unc(i32 %h_cmp1, i32 %i, i32 0)
  call void @cq_template_fcmp_olt_f80_hl_unc(i32 %h_cmp, i32 %h_op, x86_fp80 %cf)
  call void @cq_template_fsub_f80_hl_unc(i32 %h_op1, i32 %x, x86_fp80 %cf)
  call void @cq_template_fadd_f80_unc(i32 %h_op, i32 %x, i32 %h_cast)
  call void @cq_template_sitofp_i32_to_f80_unc(i32 %h_cast, i32 %i)
  call void @cqrt_free(i32 %h_cast)
  call void @cqrt_free(i32 %h_op)
  call void @cqrt_free(i32 %h_op1)
  call void @cqrt_free(i32 %h_cmp)
  call void @cqrt_free(i32 %h_cmp1)
  call void @cqrt_free(i32 %g2)
  call void @cqrt_free(i32 %out)
  call void @cqrt_free(i32 %h_cast2)
  ret i32 %cqq.out
}

declare i32 @cqrt_alloc_f80(x86_fp80)

declare void @cqrt_copy_f80_controlled(i32, i32, i32)

declare i32 @cqrt_alloc_i1(i1)

declare i32 @cq_template_fcmp_olt_f80_hl(i32, x86_fp80)

declare i32 @cq_template_icmp_ne_i32_hl(i32, i32)

declare void @cqrt_toffoli(i32, i32, i32)

declare void @cqrt_x(i32)

declare void @cqrt_free(i32)

declare void @cq_template_icmp_ne_i32_hl_unc(i32, i32, i32)

declare void @cq_template_fcmp_olt_f80_hl_unc(i32, i32, x86_fp80)

declare i32 @cq_template_sitofp_i32_to_f80(i32)

declare i32 @cq_template_fadd_f80(i32, i32)

declare i32 @cq_template_fsub_f80_hl(i32, x86_fp80)

declare i32 @cq_template_fptosi_f80_to_i32(i32)

declare i32 @cqrt_alloc_i32(i32)

declare void @cq_template_fptosi_f80_to_i32_unc(i32, i32)

declare void @cq_template_fsub_f80_hl_unc(i32, i32, x86_fp80)

declare void @cq_template_fadd_f80_unc(i32, i32, i32)

declare void @cq_template_sitofp_i32_to_f80_unc(i32, i32)

declare void @cqrt_ry_f80(i32, double)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_measure_i32(i32)

attributes #0 = { memory(readwrite) }
