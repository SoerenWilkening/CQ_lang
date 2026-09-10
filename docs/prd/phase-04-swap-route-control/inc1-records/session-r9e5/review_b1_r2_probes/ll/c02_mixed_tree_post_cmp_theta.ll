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
  %q = call i32 @cq_theta_si32(i32 0, double 2.000000e-01)
  %cc = icmp eq i32 %q, 1
  %t = and i1 %b, %cc
  %a = select i1 %t, i32 2, i32 5
  %q2 = call i32 @cq_theta_si32(i32 %q, double 3.000000e-01)
  %mm = call i32 @cq_measure_si32(i32 %q2)
  %m = call i32 @cq_measure_si32(i32 %a)
  ret i32 %m
}
