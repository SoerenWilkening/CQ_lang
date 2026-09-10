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
  %a = select i1 %b, i32 2, i32 5
  %z = zext i1 %b to i32
  %s = add i32 %z, 1
  %m = call i32 @cq_measure_si32(i32 %a)
  ret i32 %m
}
