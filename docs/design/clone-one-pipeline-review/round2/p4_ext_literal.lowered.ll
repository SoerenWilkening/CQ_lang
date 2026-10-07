; ModuleID = '/tmp/p3kd78-review-r2/p4_ext_literal.ll'
source_filename = "/tmp/p3kd78-review-r2/p4_ext_literal.ll"

define double @bool_mix(double noundef %x, i1 noundef zeroext %a, i1 noundef zeroext %b) {
entry:
  %cmp = fcmp ogt double %x, 0.000000e+00
  %one = and i1 %cmp, %a
  %two = or i1 %one, %b
  %inc = fadd double %x, 1.000000e+00
  %r = select i1 %two, double %inc, double %x
  ret double %r
}

define i32 @main(double noundef %x, i1 noundef zeroext %a, i1 noundef zeroext %b) {
entry:
  %h = call i32 @cqrt_alloc_f64(double %x)
  call void @cqrt_ry_f64(i32 %h, double 2.500000e-01)
  %r = call i32 @__cq_q_bool_mix_001(i32 %h, i1 %a, i1 %b)
  %m1 = call double @cqrt_measure_f64(i32 %r)
  ret i32 0
}

; Function Attrs: memory(readwrite)
define internal i32 @__cq_q_bool_mix_001(i32 %x, i1 noundef zeroext %a, i1 noundef zeroext %b) #0 {
entry:
  %h_op = call i32 @cq_template_fadd_f64_hl(i32 %x, double 1.000000e+00)
  %h_cmp = call i32 @cq_template_fcmp_ogt_f64_hl(i32 %x, double 0.000000e+00)
  %gl = call i32 @cq_template_and_i1_hl(i32 %h_cmp, i1 zeroext %a)
  %gl1 = call i32 @cq_template_or_i1_hl(i32 %gl, i1 zeroext %b)
  %out = call i32 @cqrt_alloc_f64(double 0.000000e+00)
  call void @cqrt_copy_f64_controlled(i32 %gl1, i32 %h_op, i32 %out)
  call void @cqrt_x(i32 %gl1)
  call void @cqrt_copy_f64_controlled(i32 %gl1, i32 %x, i32 %out)
  %cqq.out = call i32 @cqrt_alloc_f64(double 0.000000e+00)
  call void @cqrt_copy_f64(i32 %out, i32 %cqq.out)
  call void @cqrt_copy_f64_controlled(i32 %gl1, i32 %x, i32 %out)
  call void @cqrt_x(i32 %gl1)
  call void @cqrt_copy_f64_controlled(i32 %gl1, i32 %h_op, i32 %out)
  call void @cq_template_or_i1_hl_unc(i32 %gl1, i32 %gl, i1 zeroext %b)
  call void @cq_template_and_i1_hl_unc(i32 %gl, i32 %h_cmp, i1 zeroext %a)
  call void @cq_template_fcmp_ogt_f64_hl_unc(i32 %h_cmp, i32 %x, double 0.000000e+00)
  call void @cq_template_fadd_f64_hl_unc(i32 %h_op, i32 %x, double 1.000000e+00)
  call void @cqrt_free(i32 %h_op)
  call void @cqrt_free(i32 %h_cmp)
  call void @cqrt_free(i32 %gl)
  call void @cqrt_free(i32 %gl1)
  call void @cqrt_free(i32 %out)
  ret i32 %cqq.out
}

declare i32 @cqrt_alloc_f64(double)

declare void @cqrt_copy_f64_controlled(i32, i32, i32)

declare i32 @cqrt_alloc_i1(i1)

declare i32 @cq_template_fcmp_ogt_f64_hl(i32, double)

declare i32 @cq_template_and_i1_hl(i32, i1)

declare i32 @cq_template_or_i1_hl(i32, i1)

declare void @cqrt_x(i32)

declare void @cq_template_or_i1_hl_unc(i32, i32, i1)

declare void @cqrt_free(i32)

declare void @cq_template_and_i1_hl_unc(i32, i32, i1)

declare void @cq_template_fcmp_ogt_f64_hl_unc(i32, i32, double)

declare i32 @cq_template_fadd_f64_hl(i32, double)

declare void @cqrt_copy_f64(i32, i32)

declare void @cq_template_fadd_f64_hl_unc(i32, i32, double)

declare void @cqrt_ry_f64(i32, double)

declare double @cqrt_measure_f64(i32)

attributes #0 = { memory(readwrite) }
