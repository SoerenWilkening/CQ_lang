; i07 — a callee that CONTAINS a `cq_theta_i1` and a rail select (the only way a
; rail leaf could exist inside a clone). Expect the spec detector's own decline.
declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @g(i32 %a) {
  %b = call i1 @cq_theta_i1(i1 false, double 2.500000e-01)
  %z = select i1 %b, i32 %a, i32 99
  ret i32 %z
}
define i32 @main() {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %r = call i32 @g(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
