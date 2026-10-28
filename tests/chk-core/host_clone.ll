; cq-aou6: clones of host (libm) functions take the host's value, as the C oracle links it
target triple = "x86_64-apple-macosx16.0.0"
define double @hx(double %x, double %y) {
  %h = call i32 @cqrt_alloc_f64(double %x)
  %e = call i32 @__cq_q_exp_1(i32 %h)
  %a = call i32 @__cq_q_atan2_10(i32 %h, double %y, i32 4)
  %me = call double @cqrt_measure_f64(i32 %e)
  %ma = call double @cqrt_measure_f64(i32 %a)
  %p = call i32 @__cq_q_pow_10(i32 %h, double %y)
  call void @__cq_q_pow_10_unc(i32 %p, i32 %h, double %y)
  call void @cqrt_free(i32 %p)
  %s = fadd double %me, %ma
  ret double %s
}
declare i32 @cqrt_alloc_f64(double)
declare double @cqrt_measure_f64(i32)
declare void @cqrt_free(i32)
declare i32 @__cq_q_exp_1(i32)
declare i32 @__cq_q_atan2_10(i32, double, i32)
declare i32 @__cq_q_pow_10(i32, double)
declare void @__cq_q_pow_10_unc(i32, i32, double)
