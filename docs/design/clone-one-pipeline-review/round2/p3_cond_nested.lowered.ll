; ModuleID = '/tmp/p3kd78-review-r2/p3_cond_nested.ll'
source_filename = "/tmp/p3kd78-review-r2/p3_cond_nested.ll"

define double @inc(double noundef %x, double noundef %c) {
entry:
  %r = fadd double %x, %c
  ret double %r
}

define double @pick(double noundef %x, double noundef %c) {
entry:
  %inner = call double @inc(double %x, double %c)
  %test = fcmp olt double %inner, %c
  %r = select i1 %test, double %inner, double %x
  %v = fadd double %r, %c
  ret double %v
}

define i32 @main(double noundef %x, double noundef %c) {
entry:
  %h = call i32 @cqrt_alloc_f64(double %x)
  call void @cqrt_ry_f64(i32 %h, double 2.500000e-01)
  %r = call i32 @__cq_q_pick_01(i32 %h, double %c)
  %m1 = call double @cqrt_measure_f64(i32 %r)
  ret i32 0
}

; Function Attrs: memory(readwrite)
define internal i32 @__cq_q_pick_01(i32 %x, double noundef %c) #0 {
entry:
  %inner = call i32 @__cq_q_inc_01(i32 %x, double %c)
  %h_cmp = call i32 @cq_template_fcmp_olt_f64_hl(i32 %inner, double %c)
  %out = call i32 @cqrt_alloc_f64(double 0.000000e+00)
  call void @cqrt_copy_f64_controlled(i32 %h_cmp, i32 %inner, i32 %out)
  call void @cqrt_x(i32 %h_cmp)
  call void @cqrt_copy_f64_controlled(i32 %h_cmp, i32 %x, i32 %out)
  %h_op = call i32 @cq_template_fadd_f64_hl(i32 %out, double %c)
  %cqq.out = call i32 @cqrt_alloc_f64(double 0.000000e+00)
  call void @cqrt_copy_f64(i32 %h_op, i32 %cqq.out)
  call void @cq_template_fadd_f64_hl_unc(i32 %h_op, i32 %out, double %c)
  call void @cqrt_copy_f64_controlled(i32 %h_cmp, i32 %x, i32 %out)
  call void @cqrt_x(i32 %h_cmp)
  call void @cqrt_copy_f64_controlled(i32 %h_cmp, i32 %inner, i32 %out)
  call void @cq_template_fcmp_olt_f64_hl_unc(i32 %h_cmp, i32 %inner, double %c)
  call void @__cq_q_inc_01_unc(i32 %inner, i32 %x, double %c)
  call void @cqrt_free(i32 %inner)
  call void @cqrt_free(i32 %h_cmp)
  call void @cqrt_free(i32 %out)
  call void @cqrt_free(i32 %h_op)
  ret i32 %cqq.out
}

declare i32 @cqrt_alloc_f64(double)

declare void @cqrt_copy_f64_controlled(i32, i32, i32)

declare i32 @cq_template_fcmp_olt_f64_hl(i32, double)

declare void @cqrt_x(i32)

declare void @cq_template_fcmp_olt_f64_hl_unc(i32, i32, double)

declare void @cqrt_free(i32)

; Function Attrs: memory(readwrite)
define internal i32 @__cq_q_inc_01(i32 %x, double noundef %c) #0 {
entry:
  %h_op = call i32 @cq_template_fadd_f64_hl(i32 %x, double %c)
  %cqq.out = call i32 @cqrt_alloc_f64(double 0.000000e+00)
  call void @cqrt_copy_f64(i32 %h_op, i32 %cqq.out)
  call void @cq_template_fadd_f64_hl_unc(i32 %h_op, i32 %x, double %c)
  call void @cqrt_free(i32 %h_op)
  ret i32 %cqq.out
}

declare i32 @cq_template_fadd_f64_hl(i32, double)

declare void @cqrt_copy_f64(i32, i32)

declare void @cq_template_fadd_f64_hl_unc(i32, i32, double)

; Function Attrs: memory(readwrite)
define internal void @__cq_q_inc_01_unc(i32 %out, i32 %x, double noundef %c) #0 {
entry:
  %h_op = call i32 @cq_template_fadd_f64_hl(i32 %x, double %c)
  call void @cqrt_copy_f64(i32 %h_op, i32 %out)
  call void @cq_template_fadd_f64_hl_unc(i32 %h_op, i32 %x, double %c)
  call void @cqrt_free(i32 %h_op)
  ret void
}

declare void @cqrt_ry_f64(i32, double)

declare double @cqrt_measure_f64(i32)

attributes #0 = { memory(readwrite) }
