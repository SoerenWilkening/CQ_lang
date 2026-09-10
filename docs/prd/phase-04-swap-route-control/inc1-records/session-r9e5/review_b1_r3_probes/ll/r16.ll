; r16 — AREA 1: a BARE negated rail as the whole select condition (`!b`), the
; `CopyRailRoot` path's negation case.
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
define i32 @main() {
entry:
  %b = call i1 @cq_theta_i1(i1 false, double 2.500000e-01)
  %nb = xor i1 %b, true
  %s = select i1 %nb, i32 2, i32 5
  %m = call i32 @cq_measure_si32(i32 %s)
  %mm = call i1 @cq_measure_i1(i1 %b)
  %z = zext i1 %mm to i32
  %t = add i32 %m, %z
  ret i32 %t
}
