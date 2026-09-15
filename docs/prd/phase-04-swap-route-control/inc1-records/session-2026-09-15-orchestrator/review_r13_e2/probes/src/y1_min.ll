; the linked stage-1 of `int u; int q = cq_theta(0,0.3); return cq_measure(q + u);`
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)
define i32 @main() {
  %1 = call i32 @cq_theta_si32(i32 noundef 0, double noundef 3.000000e-01)
  %2 = call i32 @cq_measure_si32(i32 noundef undef)
  ret i32 %2
}
