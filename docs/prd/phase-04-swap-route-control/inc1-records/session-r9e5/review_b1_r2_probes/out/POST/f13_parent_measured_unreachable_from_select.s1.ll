; f13 — the parent is measured on a path from which the select is NOT reachable
; (the two sides of a classical diamond). The widening must still ACCEPT.
declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i64 @cq_theta_si64(i64, double)
declare i64 @cq_measure_si64(i64)
@g = global i32 0
define i32 @main() {
entry:
  %b0 = call i1 @cq_theta_i1(i1 false, double 2.000000e-01)
  %b = call i1 @cq_theta_i1(i1 %b0, double 5.000000e-01)
  %g = load volatile i32, ptr @g
  %cc = icmp sgt i32 %g, 7
  br i1 %cc, label %L, label %R
L:
  %mm = call i1 @cq_measure_i1(i1 %b0)
  %zz = zext i1 %mm to i32
  ret i32 %zz
R:
  %a = select i1 %b, i32 7, i32 9
  %m = call i32 @cq_measure_si32(i32 %a)
  ret i32 %m
}
