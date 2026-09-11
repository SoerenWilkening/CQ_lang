declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare double @llvm.fabs.f64(double)
define double @example(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %c = fcmp oeq double %q, -5.000000e+00
  br i1 %c, label %arm, label %merge
arm:
  %rt = call double @cq_theta_f64(double 5.000000e+00, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi double [ %rt, %arm ], [ 5.000000e+00, %entry ]
  %d  = call double @llvm.fabs.f64(double %q)
  %mr = call double @cq_measure_f64(double %rm)
  %md = call double @cq_measure_f64(double %d)
  %s  = fadd double %mr, %md
  ret double %s
}
