declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

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
  %x = call double @cq_theta_f64(double %a, double 0.25)
  %y = call double @cq_theta_f64(double %b, double 0.5)
  %u = call double @middle(double %x, double %k)
  %mu = call double @cq_measure_f64(double %u)
  %v = call double @middle(double %k, double %y)
  %mv = call double @cq_measure_f64(double %v)
  %w = call double @middle(double %x, double %y)
  %mw = call double @cq_measure_f64(double %w)
  ret i32 0
}
