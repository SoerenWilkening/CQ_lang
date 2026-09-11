; HAND IR (r903 probe t9) — a tainted `trunc i32 -> i1` used as DATA only, to
; measure what CastLowering mints for the derived-i1 rail (item 3's mint).
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @main(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 3.000000e-01)
  %t = trunc i32 %q to i1
  %m = call i1 @cq_measure_i1(i1 %t)
  %z = zext i1 %m to i32
  ret i32 %z
}
