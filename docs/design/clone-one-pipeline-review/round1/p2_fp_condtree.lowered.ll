; ModuleID = '/tmp/p3kd78-review-r1/p2_fp_condtree.ll'
source_filename = "/tmp/p3kd78-review-r1/p2_fp_condtree.ll"
target triple = "x86_64-unknown-linux-gnu"

define internal double @fpcalc(double noundef %a, double noundef %b) {
entry:
  %c1 = fcmp olt double %a, %b
  %c2 = fcmp une double %a, 0.000000e+00
  %c = and i1 %c1, %c2
  %t = fadd double %a, %b
  %f = fsub double %a, 1.000000e+00
  %r = select i1 %c, double %t, double %f
  ret double %r
}

define double @probe(double %x, double %y) {
  %h = call i32 @cqrt_alloc_f64(double %x)
  call void @cqrt_ry_f64(i32 %h, double 5.000000e-01)
  %h1 = call i32 @cqrt_alloc_f64(double %y)
  call void @cqrt_ry_f64(i32 %h1, double 7.500000e-01)
  %r = call i32 @__cq_q_fpcalc_11(i32 %h, i32 %h1)
  %m2 = call double @cqrt_measure_f64(i32 %r)
  ret double %m2
}

; Function Attrs: memory(readwrite)
define internal i32 @__cq_q_fpcalc_11(i32 %a, i32 %b) #0 {
entry:
  %h_op = call i32 @cq_template_fadd_f64(i32 %a, i32 %b)
  %h_op1 = call i32 @cq_template_fsub_f64_hl(i32 %a, double 1.000000e+00)
  %h_cmp = call i32 @cq_template_fcmp_olt_f64(i32 %a, i32 %b)
  %h_cmp1 = call i32 @cq_template_fcmp_une_f64_hl(i32 %a, double 0.000000e+00)
  %g = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_toffoli(i32 %h_cmp, i32 %h_cmp1, i32 %g)
  %out = call i32 @cqrt_alloc_f64(double 0.000000e+00)
  call void @cqrt_copy_f64_controlled(i32 %g, i32 %h_op, i32 %out)
  call void @cqrt_x(i32 %g)
  call void @cqrt_copy_f64_controlled(i32 %g, i32 %h_op1, i32 %out)
  %cqq.out = call i32 @cqrt_alloc_f64(double 0.000000e+00)
  call void @cqrt_copy_f64(i32 %out, i32 %cqq.out)
  call void @cqrt_copy_f64_controlled(i32 %g, i32 %h_op1, i32 %out)
  call void @cqrt_x(i32 %g)
  call void @cqrt_copy_f64_controlled(i32 %g, i32 %h_op, i32 %out)
  call void @cqrt_toffoli(i32 %h_cmp, i32 %h_cmp1, i32 %g)
  call void @cq_template_fcmp_une_f64_hl_unc(i32 %h_cmp1, i32 %a, double 0.000000e+00)
  call void @cq_template_fcmp_olt_f64_unc(i32 %h_cmp, i32 %a, i32 %b)
  call void @cq_template_fsub_f64_hl_unc(i32 %h_op1, i32 %a, double 1.000000e+00)
  call void @cq_template_fadd_f64_unc(i32 %h_op, i32 %a, i32 %b)
  call void @cqrt_free(i32 %h_op)
  call void @cqrt_free(i32 %h_op1)
  call void @cqrt_free(i32 %h_cmp)
  call void @cqrt_free(i32 %h_cmp1)
  call void @cqrt_free(i32 %g)
  call void @cqrt_free(i32 %out)
  ret i32 %cqq.out
}

declare i32 @cqrt_alloc_f64(double)

declare void @cqrt_copy_f64_controlled(i32, i32, i32)

declare i32 @cqrt_alloc_i1(i1)

declare i32 @cq_template_fcmp_olt_f64(i32, i32)

declare i32 @cq_template_fcmp_une_f64_hl(i32, double)

declare void @cqrt_toffoli(i32, i32, i32)

declare void @cqrt_x(i32)

declare void @cqrt_free(i32)

declare void @cq_template_fcmp_une_f64_hl_unc(i32, i32, double)

declare void @cq_template_fcmp_olt_f64_unc(i32, i32, i32)

declare i32 @cq_template_fadd_f64(i32, i32)

declare i32 @cq_template_fsub_f64_hl(i32, double)

declare void @cqrt_copy_f64(i32, i32)

declare void @cq_template_fsub_f64_hl_unc(i32, i32, double)

declare void @cq_template_fadd_f64_unc(i32, i32, i32)

declare void @cqrt_ry_f64(i32, double)

declare double @cqrt_measure_f64(i32)

attributes #0 = { memory(readwrite) }
