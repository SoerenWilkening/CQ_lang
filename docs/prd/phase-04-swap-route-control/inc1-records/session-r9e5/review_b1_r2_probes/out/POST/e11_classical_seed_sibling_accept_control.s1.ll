; e11 — THE DISCRIMINATOR for e04: the same two-sibling shape whose seed `%x` is
; classical at round 1 AND STAYS classical (an opaque classical i1). Both thetas
; are then SOURCE thetas and mint TWO SEPARATE registers, so the accept is
; CORRECT and the select's control reads its own rail. Green everywhere.
@gbit = global i1 false
declare i32 @cq_measure_si32(i32)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
define i32 @main() {
entry:
  %x = load volatile i1, ptr @gbit
  %b = call i1 @cq_theta_i1(i1 %x, double 5.000000e-01)
  %b3 = call i1 @cq_theta_i1(i1 %x, double 9.000000e-01)
  %a = select i1 %b, i32 2, i32 5
  %mm = call i1 @cq_measure_i1(i1 %b3)
  %zz = zext i1 %mm to i32
  %m = call i32 @cq_measure_si32(i32 %a)
  %t = add i32 %m, %zz
  ret i32 %t
}
