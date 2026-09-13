declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare double @llvm.sqrt.f64(double)
define double @example(double %u) {
entry:
  %q = call double @cq_theta_f64(double %u, double 5.000000e-01)
  %d = call double @llvm.sqrt.f64(double %q)
  %m = call double @cq_measure_f64(double %d)
  ret double %m
}
