; ModuleID = '/tmp/p3kd78-review-r2/p5_qram_return.ll'
source_filename = "/tmp/p3kd78-review-r2/p5_qram_return.ll"

@table = private constant [4 x double] [double 1.000000e+00, double 2.000000e+00, double 3.000000e+00, double 4.000000e+00]

declare i32 @cq_theta_i32(i32, double)

define double @lookup(double noundef %x, i32 noundef %idx) {
entry:
  %bits = bitcast double %x to i64
  %low = trunc i64 %bits to i32
  %mix = xor i32 %low, %idx
  %small = and i32 %mix, 3
  %wide = zext i32 %small to i64
  %p = getelementptr inbounds [4 x double], ptr @table, i64 0, i64 %wide
  %r = load double, ptr %p, align 8
  ret double %r
}

define double @outer_lookup(double noundef %x, i32 noundef %idx) {
entry:
  %r = call double @lookup(double %x, i32 %idx)
  %v = fmul double %r, 2.000000e+00
  ret double %v
}

define i32 @main(double noundef %x, i32 noundef %idx) {
entry:
  %h = call i32 @cqrt_alloc_f64(double %x)
  call void @cqrt_ry_f64(i32 %h, double 2.500000e-01)
  %i = call i32 @cq_theta_i32(i32 %idx, double 5.000000e-01)
  %r = call i32 @__cq_q_outer_lookup_01(i32 %h, i32 %i)
  %m1 = call double @cqrt_measure_f64(i32 %r)
  ret i32 0
}

; Function Attrs: memory(readwrite)
define internal i32 @__cq_q_outer_lookup_01(i32 %x, i32 noundef %idx) #0 {
entry:
  %r = call i32 @__cq_q_lookup_01(i32 %x, i32 %idx)
  %h_op = call i32 @cq_template_fmul_f64_hl(i32 %r, double 2.000000e+00)
  %cqq.out = call i32 @cqrt_alloc_f64(double 0.000000e+00)
  call void @cqrt_copy_f64(i32 %h_op, i32 %cqq.out)
  call void @cq_template_fmul_f64_hl_unc(i32 %h_op, i32 %r, double 2.000000e+00)
  call void @__cq_q_lookup_01_unc(i32 %r, i32 %x, i32 %idx)
  call void @cqrt_free(i32 %r)
  call void @cqrt_free(i32 %h_op)
  ret i32 %cqq.out
}

; Function Attrs: memory(readwrite)
define internal i32 @__cq_q_lookup_01(i32 %x, i32 noundef %idx) #0 {
entry:
  %arr = call i32 @cqrt_qram_alloc_f64(i32 4)
  %h_cast = call i32 @cq_template_bitcast_f64_to_i64(i32 %x)
  %h_cast1 = call i32 @cq_template_trunc_i64_to_i32(i32 %h_cast)
  %h_op = call i32 @cq_template_xor_i32_hl(i32 %h_cast1, i32 %idx)
  %h_op2 = call i32 @cq_template_and_i32_hl(i32 %h_op, i32 3)
  %0 = call i32 @cqrt_qram_load_f64(i32 %arr, i32 %h_op2)
  %cqq.out = call i32 @cqrt_alloc_f64(double 0.000000e+00)
  call void @cqrt_copy_f64(i32 %0, i32 %cqq.out)
  call void @cqrt_qram_load_f64_unc(i32 %0, i32 %arr, i32 %h_op2)
  call void @cq_template_and_i32_hl_unc(i32 %h_op2, i32 %h_op, i32 3)
  call void @cq_template_xor_i32_hl_unc(i32 %h_op, i32 %h_cast1, i32 %idx)
  call void @cq_template_trunc_i64_to_i32_unc(i32 %h_cast1, i32 %h_cast)
  call void @cq_template_bitcast_f64_to_i64_unc(i32 %h_cast, i32 %x)
  call void @cqrt_free(i32 %h_cast)
  call void @cqrt_free(i32 %h_cast1)
  call void @cqrt_free(i32 %h_op)
  call void @cqrt_free(i32 %h_op2)
  call void @cqrt_free(i32 %0)
  ret i32 %cqq.out
}

declare i32 @cqrt_qram_alloc_f64(i32)

declare i32 @cqrt_qram_load_f64(i32, i32)

declare i32 @cq_template_bitcast_f64_to_i64(i32)

declare i32 @cq_template_trunc_i64_to_i32(i32)

declare i32 @cq_template_xor_i32_hl(i32, i32)

declare i32 @cq_template_and_i32_hl(i32, i32)

declare i32 @cqrt_alloc_f64(double)

declare void @cqrt_copy_f64(i32, i32)

declare void @cqrt_qram_load_f64_unc(i32, i32, i32)

declare void @cq_template_and_i32_hl_unc(i32, i32, i32)

declare void @cq_template_xor_i32_hl_unc(i32, i32, i32)

declare void @cq_template_trunc_i64_to_i32_unc(i32, i32)

declare void @cq_template_bitcast_f64_to_i64_unc(i32, i32)

declare void @cqrt_free(i32)

; Function Attrs: memory(readwrite)
define internal void @__cq_q_lookup_01_unc(i32 %out, i32 %x, i32 noundef %idx) #0 {
entry:
  %arr = call i32 @cqrt_qram_alloc_f64(i32 4)
  %h_cast = call i32 @cq_template_bitcast_f64_to_i64(i32 %x)
  %h_cast1 = call i32 @cq_template_trunc_i64_to_i32(i32 %h_cast)
  %h_op = call i32 @cq_template_xor_i32_hl(i32 %h_cast1, i32 %idx)
  %h_op2 = call i32 @cq_template_and_i32_hl(i32 %h_op, i32 3)
  %0 = call i32 @cqrt_qram_load_f64(i32 %arr, i32 %h_op2)
  call void @cqrt_copy_f64(i32 %0, i32 %out)
  call void @cqrt_qram_load_f64_unc(i32 %0, i32 %arr, i32 %h_op2)
  call void @cq_template_and_i32_hl_unc(i32 %h_op2, i32 %h_op, i32 3)
  call void @cq_template_xor_i32_hl_unc(i32 %h_op, i32 %h_cast1, i32 %idx)
  call void @cq_template_trunc_i64_to_i32_unc(i32 %h_cast1, i32 %h_cast)
  call void @cq_template_bitcast_f64_to_i64_unc(i32 %h_cast, i32 %x)
  call void @cqrt_free(i32 %h_cast)
  call void @cqrt_free(i32 %h_cast1)
  call void @cqrt_free(i32 %h_op)
  call void @cqrt_free(i32 %h_op2)
  call void @cqrt_free(i32 %0)
  ret void
}

declare i32 @cq_template_fmul_f64_hl(i32, double)

declare void @cq_template_fmul_f64_hl_unc(i32, i32, double)

declare void @cqrt_ry_f64(i32, double)

declare double @cqrt_measure_f64(i32)

attributes #0 = { memory(readwrite) }
