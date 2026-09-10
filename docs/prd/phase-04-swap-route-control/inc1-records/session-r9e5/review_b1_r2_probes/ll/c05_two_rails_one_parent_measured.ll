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
  %c0 = call i1 @cq_theta_i1(i1 true, double 6.000000e-01)
  %c = call i1 @cq_theta_i1(i1 %c0, double 7.000000e-01)
  %t = xor i1 %b, %c
  %mm = call i1 @cq_measure_i1(i1 %c0)
  %a = select i1 %t, i32 2, i32 5
  %m = call i32 @cq_measure_si32(i32 %a)
  ret i32 %m
}
