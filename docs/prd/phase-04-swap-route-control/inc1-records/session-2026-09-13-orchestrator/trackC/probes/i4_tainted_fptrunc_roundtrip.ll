declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
define double @example(double %u) {
entry:
  %q = call double @cq_theta_f64(double %u, double 5.000000e-01)
  %d = fneg double %q
  %e = fptrunc double %d to float
  %f = fpext float %e to double
  %m = call double @cq_measure_f64(double %f)
  ret double %m
}
