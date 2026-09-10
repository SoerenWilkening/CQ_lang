declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
define i32 @main() {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %cc = icmp eq i32 %q, 1
  %a = select i1 %cc, i32 2, i32 5
  %c = add i32 %a, 3
  %d = mul i32 %c, 7
  %m = call i32 @cq_measure_si32(i32 %a)
  ret i32 %m
}
