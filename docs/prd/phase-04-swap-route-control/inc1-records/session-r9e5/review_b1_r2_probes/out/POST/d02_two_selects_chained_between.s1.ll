declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
define i32 @main() {
entry:
  %b = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %a1 = select i1 %b, i32 2, i32 5
  %b2 = call i1 @cq_theta_i1(i1 %b, double 3.000000e-01)
  %a2 = select i1 %b2, i32 7, i32 9
  %m1 = call i32 @cq_measure_si32(i32 %a1)
  %m2 = call i32 @cq_measure_si32(i32 %a2)
  %r = add i32 %m1, %m2
  ret i32 %r
}
