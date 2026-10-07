declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @bool_mix(double noundef %x, i1 noundef zeroext %a, i1 noundef zeroext %b) {
entry:
  %cmp = fcmp ogt double %x, 0.0
  %one = and i1 %cmp, %a
  %two = or i1 %one, %b
  %inc = fadd double %x, 1.0
  %r = select i1 %two, double %inc, double %x
  ret double %r
}

define i32 @main(double noundef %x, i1 noundef zeroext %a, i1 noundef zeroext %b) {
entry:
  %q = call double @cq_theta_f64(double %x, double 0.25)
  %r = call double @bool_mix(double %q, i1 zeroext %a, i1 zeroext %b)
  %m = call double @cq_measure_f64(double %r)
  ret i32 0
}
