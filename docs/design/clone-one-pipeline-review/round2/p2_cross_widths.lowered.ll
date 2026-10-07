; ModuleID = '/tmp/p3kd78-review-r2/p2_cross_widths.ll'
source_filename = "/tmp/p3kd78-review-r2/p2_cross_widths.ll"

define double @width_mix(float noundef nofpclass(nan inf) %x, double noundef nofpclass(nan inf) %c, i32 noundef range(i32 1, 100) %bias) {
entry:
  %w = fpext float %x to double
  %q = fadd double %w, %c
  %b = sitofp i32 %bias to double
  %r = fmul double %q, %b
  ret double %r
}

define i32 @main(float noundef %x, double noundef %c, i32 noundef range(i32 1, 100) %b) {
entry:
  %h = call i32 @cqrt_alloc_f32(float %x)
  call void @cqrt_ry_f32(i32 %h, double 2.500000e-01)
  %r = call i32 @__cq_q_width_mix_001(i32 %h, double %c, i32 %b)
  %m1 = call double @cqrt_measure_f64(i32 %r)
  ret i32 0
}

; Function Attrs: memory(readwrite)
define internal i32 @__cq_q_width_mix_001(i32 %x, double noundef nofpclass(nan inf) %c, i32 noundef range(i32 1, 100) %bias) #0 {
entry:
  %h_cast = call i32 @cq_template_fpext_f32_to_f64(i32 %x)
  %h_op = call i32 @cq_template_fadd_f64_hl(i32 %h_cast, double %c)
  %b = sitofp i32 %bias to double
  %h_op1 = call i32 @cq_template_fmul_f64_hl(i32 %h_op, double %b)
  %cqq.out = call i32 @cqrt_alloc_f64(double 0.000000e+00)
  call void @cqrt_copy_f64(i32 %h_op1, i32 %cqq.out)
  call void @cq_template_fmul_f64_hl_unc(i32 %h_op1, i32 %h_op, double %b)
  call void @cq_template_fadd_f64_hl_unc(i32 %h_op, i32 %h_cast, double %c)
  call void @cq_template_fpext_f32_to_f64_unc(i32 %h_cast, i32 %x)
  call void @cqrt_free(i32 %h_cast)
  call void @cqrt_free(i32 %h_op)
  call void @cqrt_free(i32 %h_op1)
  ret i32 %cqq.out
}

declare i32 @cq_template_fpext_f32_to_f64(i32)

declare i32 @cq_template_fadd_f64_hl(i32, double)

declare i32 @cq_template_fmul_f64_hl(i32, double)

declare i32 @cqrt_alloc_f64(double)

declare void @cqrt_copy_f64(i32, i32)

declare void @cq_template_fmul_f64_hl_unc(i32, i32, double)

declare void @cq_template_fadd_f64_hl_unc(i32, i32, double)

declare void @cq_template_fpext_f32_to_f64_unc(i32, i32)

declare void @cqrt_free(i32)

declare void @cqrt_ry_f32(i32, double)

declare i32 @cqrt_alloc_f32(float)

declare double @cqrt_measure_f64(i32)

attributes #0 = { memory(readwrite) }
