; ModuleID = '/tmp/p3kd78-review-r2/p1_nested_masks.ll'
source_filename = "/tmp/p3kd78-review-r2/p1_nested_masks.ll"

define double @leaf(double noundef nofpclass(nan inf) %a, double noundef %b) {
entry:
  %r = fadd double %a, %b
  ret double %r
}

define double @middle(double noundef %x, double noundef %y) {
entry:
  %u = call double @leaf(double %x, double %y)
  %v = call double @leaf(double %x, double %y)
  %r = fsub double %u, %v
  ret double %r
}

define i32 @main(double noundef %a, double noundef %b, double noundef %k) {
entry:
  %h = call i32 @cqrt_alloc_f64(double %a)
  call void @cqrt_ry_f64(i32 %h, double 2.500000e-01)
  %h1 = call i32 @cqrt_alloc_f64(double %b)
  call void @cqrt_ry_f64(i32 %h1, double 5.000000e-01)
  %u = call i32 @__cq_q_middle_01(i32 %h, double %k)
  %m = call double @cqrt_measure_f64(i32 %u)
  %v = call i32 @__cq_q_middle_10(double %k, i32 %h1)
  %m2 = call double @cqrt_measure_f64(i32 %v)
  %w = call i32 @__cq_q_middle_11(i32 %h, i32 %h1)
  %m3 = call double @cqrt_measure_f64(i32 %w)
  ret i32 0
}

; Function Attrs: memory(readwrite)
define internal i32 @__cq_q_middle_01(i32 %x, double noundef %y) #0 {
entry:
  %u = call i32 @__cq_q_leaf_01(i32 %x, double %y)
  %v = call i32 @__cq_q_leaf_01(i32 %x, double %y)
  %h_op = call i32 @cq_template_fsub_f64(i32 %u, i32 %v)
  %cqq.out = call i32 @cqrt_alloc_f64(double 0.000000e+00)
  call void @cqrt_copy_f64(i32 %h_op, i32 %cqq.out)
  call void @cq_template_fsub_f64_unc(i32 %h_op, i32 %u, i32 %v)
  call void @__cq_q_leaf_01_unc(i32 %v, i32 %x, double %y)
  call void @__cq_q_leaf_01_unc(i32 %u, i32 %x, double %y)
  call void @cqrt_free(i32 %u)
  call void @cqrt_free(i32 %v)
  call void @cqrt_free(i32 %h_op)
  ret i32 %cqq.out
}

; Function Attrs: memory(readwrite)
define internal i32 @__cq_q_leaf_01(i32 %a, double noundef %b) #0 {
entry:
  %h_op = call i32 @cq_template_fadd_f64_hl(i32 %a, double %b)
  %cqq.out = call i32 @cqrt_alloc_f64(double 0.000000e+00)
  call void @cqrt_copy_f64(i32 %h_op, i32 %cqq.out)
  call void @cq_template_fadd_f64_hl_unc(i32 %h_op, i32 %a, double %b)
  call void @cqrt_free(i32 %h_op)
  ret i32 %cqq.out
}

declare i32 @cq_template_fadd_f64_hl(i32, double)

declare i32 @cqrt_alloc_f64(double)

declare void @cqrt_copy_f64(i32, i32)

declare void @cq_template_fadd_f64_hl_unc(i32, i32, double)

declare void @cqrt_free(i32)

; Function Attrs: memory(readwrite)
define internal void @__cq_q_leaf_01_unc(i32 %out, i32 %a, double noundef %b) #0 {
entry:
  %h_op = call i32 @cq_template_fadd_f64_hl(i32 %a, double %b)
  call void @cqrt_copy_f64(i32 %h_op, i32 %out)
  call void @cq_template_fadd_f64_hl_unc(i32 %h_op, i32 %a, double %b)
  call void @cqrt_free(i32 %h_op)
  ret void
}

declare i32 @cq_template_fsub_f64(i32, i32)

declare void @cq_template_fsub_f64_unc(i32, i32, i32)

; Function Attrs: memory(readwrite)
define internal i32 @__cq_q_middle_10(double noundef %x, i32 %y) #0 {
entry:
  %u = call i32 @__cq_q_leaf_10(double %x, i32 %y)
  %v = call i32 @__cq_q_leaf_10(double %x, i32 %y)
  %h_op = call i32 @cq_template_fsub_f64(i32 %u, i32 %v)
  %cqq.out = call i32 @cqrt_alloc_f64(double 0.000000e+00)
  call void @cqrt_copy_f64(i32 %h_op, i32 %cqq.out)
  call void @cq_template_fsub_f64_unc(i32 %h_op, i32 %u, i32 %v)
  call void @__cq_q_leaf_10_unc(i32 %v, double %x, i32 %y)
  call void @__cq_q_leaf_10_unc(i32 %u, double %x, i32 %y)
  call void @cqrt_free(i32 %u)
  call void @cqrt_free(i32 %v)
  call void @cqrt_free(i32 %h_op)
  ret i32 %cqq.out
}

; Function Attrs: memory(readwrite)
define internal i32 @__cq_q_leaf_10(double noundef nofpclass(nan inf) %a, i32 %b) #0 {
entry:
  %h_op = call i32 @cq_template_fadd_f64_hl(i32 %b, double %a)
  %cqq.out = call i32 @cqrt_alloc_f64(double 0.000000e+00)
  call void @cqrt_copy_f64(i32 %h_op, i32 %cqq.out)
  call void @cq_template_fadd_f64_hl_unc(i32 %h_op, i32 %b, double %a)
  call void @cqrt_free(i32 %h_op)
  ret i32 %cqq.out
}

; Function Attrs: memory(readwrite)
define internal void @__cq_q_leaf_10_unc(i32 %out, double noundef nofpclass(nan inf) %a, i32 %b) #0 {
entry:
  %h_op = call i32 @cq_template_fadd_f64_hl(i32 %b, double %a)
  call void @cqrt_copy_f64(i32 %h_op, i32 %out)
  call void @cq_template_fadd_f64_hl_unc(i32 %h_op, i32 %b, double %a)
  call void @cqrt_free(i32 %h_op)
  ret void
}

; Function Attrs: memory(readwrite)
define internal i32 @__cq_q_middle_11(i32 %x, i32 %y) #0 {
entry:
  %u = call i32 @__cq_q_leaf_11(i32 %x, i32 %y)
  %v = call i32 @__cq_q_leaf_11(i32 %x, i32 %y)
  %h_op = call i32 @cq_template_fsub_f64(i32 %u, i32 %v)
  %cqq.out = call i32 @cqrt_alloc_f64(double 0.000000e+00)
  call void @cqrt_copy_f64(i32 %h_op, i32 %cqq.out)
  call void @cq_template_fsub_f64_unc(i32 %h_op, i32 %u, i32 %v)
  call void @__cq_q_leaf_11_unc(i32 %v, i32 %x, i32 %y)
  call void @__cq_q_leaf_11_unc(i32 %u, i32 %x, i32 %y)
  call void @cqrt_free(i32 %u)
  call void @cqrt_free(i32 %v)
  call void @cqrt_free(i32 %h_op)
  ret i32 %cqq.out
}

; Function Attrs: memory(readwrite)
define internal i32 @__cq_q_leaf_11(i32 %a, i32 %b) #0 {
entry:
  %h_op = call i32 @cq_template_fadd_f64(i32 %a, i32 %b)
  %cqq.out = call i32 @cqrt_alloc_f64(double 0.000000e+00)
  call void @cqrt_copy_f64(i32 %h_op, i32 %cqq.out)
  call void @cq_template_fadd_f64_unc(i32 %h_op, i32 %a, i32 %b)
  call void @cqrt_free(i32 %h_op)
  ret i32 %cqq.out
}

declare i32 @cq_template_fadd_f64(i32, i32)

declare void @cq_template_fadd_f64_unc(i32, i32, i32)

; Function Attrs: memory(readwrite)
define internal void @__cq_q_leaf_11_unc(i32 %out, i32 %a, i32 %b) #0 {
entry:
  %h_op = call i32 @cq_template_fadd_f64(i32 %a, i32 %b)
  call void @cqrt_copy_f64(i32 %h_op, i32 %out)
  call void @cq_template_fadd_f64_unc(i32 %h_op, i32 %a, i32 %b)
  call void @cqrt_free(i32 %h_op)
  ret void
}

declare void @cqrt_ry_f64(i32, double)

declare double @cqrt_measure_f64(i32)

attributes #0 = { memory(readwrite) }
