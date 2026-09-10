; g08 — the rail is BOTH the condition and the true arm (bd big5 CASE A).
declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i64 @cq_theta_si64(i64, double)
declare i64 @cq_measure_si64(i64)
define i32 @main() {
entry:
  %b = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %c = call i1 @cq_theta_i1(i1 true, double 7.000000e-01)
  %a = select i1 %b, i1 %b, i1 %c
  %za = zext i1 %a to i32
  %m = call i32 @cq_measure_si32(i32 %za)
  ret i32 %m
}
