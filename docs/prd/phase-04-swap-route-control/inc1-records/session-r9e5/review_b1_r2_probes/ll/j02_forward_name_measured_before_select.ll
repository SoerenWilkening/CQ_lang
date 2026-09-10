; j02 — the FORWARD name defined AND measured BEFORE the select: rung (iii) must
; refuse it (the theta is not provably post-select).
declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @main() {
entry:
  %b = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %c = call i1 @cq_theta_i1(i1 %b, double 3.000000e-01)
  %mc = call i1 @cq_measure_i1(i1 %c)
  %a = select i1 %b, i32 2, i32 5
  %zc = zext i1 %mc to i32
  %ma = call i32 @cq_measure_si32(i32 %a)
  %r = add i32 %ma, %zc
  ret i32 %r
}
