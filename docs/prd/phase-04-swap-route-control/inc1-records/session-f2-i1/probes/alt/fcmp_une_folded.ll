
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @example(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %t = fmul double %q, 2.000000e+00
  %c = fcmp une double %t, 5.000000e+00
  br i1 %c, label %merge, label %arm
arm:
  %rt = call double @cq_theta_f64(double %t, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi double [ %rt, %arm ], [ 5.000000e+00, %entry ]
  %mr = call double @cq_measure_f64(double %rm)
  %mt = call double @cq_measure_f64(double %t)
  %s  = fadd double %mr, %mt
  ret double %s
}
