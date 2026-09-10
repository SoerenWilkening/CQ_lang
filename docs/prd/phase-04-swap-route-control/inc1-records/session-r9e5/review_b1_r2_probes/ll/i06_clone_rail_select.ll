; i06 — a rail-conditioned select inside a SPECIALIZATION CANDIDATE (the callee
; is cloned on taint). `lowerCloneSelect` SKIPS a rail-carrying tree; the
; buildClone backstop must then decline it LOUDLY — never a third path.
declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @g(i32 %a, i1 %bb) {
  %z = select i1 %bb, i32 %a, i32 99
  %s = add i32 %z, 1
  ret i32 %s
}
define i32 @main() {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %b = call i1 @cq_theta_i1(i1 false, double 2.500000e-01)
  %r = call i32 @g(i32 %q, i1 %b)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
