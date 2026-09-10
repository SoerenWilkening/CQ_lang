; g06 — the `&&` spelling: `select i1 %b, i1 %cmp, i1 false` as the condition.
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
  %q = call i32 @cq_theta_si32(i32 0, double 2.000000e-01)
  %cc = icmp eq i32 %q, 1
  %t = select i1 %b, i1 %cc, i1 false
  %a = select i1 %t, i32 2, i32 5
  %m = call i32 @cq_measure_si32(i32 %a)
  ret i32 %m
}
