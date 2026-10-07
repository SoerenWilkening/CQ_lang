target triple = "x86_64-unknown-linux-gnu"
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
define internal double @fpcalc(double noundef %a, double noundef %b) {
entry:
 %c1 = fcmp olt double %a, %b
 %c2 = fcmp une double %a, 0.0
 %c = and i1 %c1, %c2
 %t = fadd double %a, %b
 %f = fsub double %a, 1.0
 %r = select i1 %c, double %t, double %f
 ret double %r
}
define double @probe(double %x, double %y) {
 %q = call double @cq_theta_f64(double %x, double 0.5)
 %s = call double @cq_theta_f64(double %y, double 0.75)
 %r = call double @fpcalc(double %q, double %s)
 %m = call double @cq_measure_f64(double %r)
 ret double %m
}
