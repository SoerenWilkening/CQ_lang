; g05 — an i64 data select on a bare rail with a post-select theta.
declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i64 @cq_theta_sll(i64, double)
declare i64 @cq_measure_sll(i64)
define i64 @main() {
entry:
  %b = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %a = select i1 %b, i64 7, i64 9
  %b2 = call i1 @cq_theta_i1(i1 %b, double 3.000000e-01)
  %mm = call i1 @cq_measure_i1(i1 %b2)
  %m = call i64 @cq_measure_sll(i64 %a)
  ret i64 %m
}
