; e05 — THE CONTROL for e04: the same two-sibling shape with `%x` TAINTED AT
; ROUND 1 (derived from `%q` directly). Inc 1b's F-1b-1 widening must DECLINE.
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
define i32 @main() {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %x = trunc i32 %q to i1
  %b = call i1 @cq_theta_i1(i1 %x, double 5.000000e-01)
  %b3 = call i1 @cq_theta_i1(i1 %x, double 9.000000e-01)
  %a = select i1 %b, i32 2, i32 5
  %mm = call i1 @cq_measure_i1(i1 %b3)
  %zz = zext i1 %mm to i32
  %m = call i32 @cq_measure_si32(i32 %a)
  %t = add i32 %m, %zz
  ret i32 %t
}
