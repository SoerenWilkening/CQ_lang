declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
define double @example(double %u) {
entry:
  %q = call double @cq_theta_f64(double %u, double 5.000000e-01)
  %v = insertelement <2 x double> zeroinitializer, double %q, i32 0
  %d = extractelement <2 x double> %v, i32 0
  %m = call double @cq_measure_f64(double %d)
  ret double %m
}
