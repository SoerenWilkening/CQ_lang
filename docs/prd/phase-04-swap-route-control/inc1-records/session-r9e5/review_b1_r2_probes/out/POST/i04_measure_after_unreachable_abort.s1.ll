; i04 — the parent is measured only on a path that ends in `unreachable`
; (the 7.2 abort shape). `isPotentiallyReachable` should say the select is NOT
; reachable from it — an over-decline probe for the widening.
@g = global i32 0
declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @main() {
entry:
  %b0 = call i1 @cq_theta_i1(i1 false, double 2.000000e-01)
  %b = call i1 @cq_theta_i1(i1 %b0, double 5.000000e-01)
  %g = load volatile i32, ptr @g
  %cc = icmp sgt i32 %g, 7
  br i1 %cc, label %bad, label %ok
bad:
  %mm = call i1 @cq_measure_i1(i1 %b0)
  unreachable
ok:
  %a = select i1 %b, i32 2, i32 5
  %m = call i32 @cq_measure_si32(i32 %a)
  ret i32 %m
}
