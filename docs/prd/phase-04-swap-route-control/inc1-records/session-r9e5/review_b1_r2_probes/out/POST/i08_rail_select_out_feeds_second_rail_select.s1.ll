; i08 — NESTING: the first rail select's %out feeds the SECOND rail select's arm.
declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @main() {
entry:
  %b = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %c = call i1 @cq_theta_i1(i1 true, double 6.000000e-01)
  %a1 = select i1 %b, i32 2, i32 5
  %a2 = select i1 %c, i32 %a1, i32 9
  %m = call i32 @cq_measure_si32(i32 %a2)
  ret i32 %m
}
