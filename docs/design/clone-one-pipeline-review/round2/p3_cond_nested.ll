declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

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
  %q = call double @cq_theta_f64(double %x, double 0.25)
  %r = call double @pick(double %q, double %c)
  %m = call double @cq_measure_f64(double %r)
  ret i32 0
}
