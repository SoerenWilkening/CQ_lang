declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
define double @main() {
entry:
  %b = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %a = select i1 %b, double 2.000000e+00, double 5.000000e+00
  %b2 = call i1 @cq_theta_i1(i1 %b, double 3.000000e-01)
  %mm = call i1 @cq_measure_i1(i1 %b2)
  %m = call double @cq_measure_f64(double %a)
  ret double %m
}
