declare float @cq_theta_f32(float, double)
declare double @cq_measure_f64(double)

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
  %q = call float @cq_theta_f32(float %x, double 0.25)
  %r = call double @width_mix(float %q, double %c, i32 %b)
  %m = call double @cq_measure_f64(double %r)
  ret i32 0
}
