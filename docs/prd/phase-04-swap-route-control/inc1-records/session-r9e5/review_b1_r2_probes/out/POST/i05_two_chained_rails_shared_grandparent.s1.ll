; i05 — TWO chained rails sharing ONE grandparent, the select on the second and
; the FIRST measured: they are the SAME physical wire, so this must decline.
declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @main() {
entry:
  %g0 = call i1 @cq_theta_i1(i1 false, double 1.000000e-01)
  %p = call i1 @cq_theta_i1(i1 %g0, double 2.000000e-01)
  %b = call i1 @cq_theta_i1(i1 %p, double 5.000000e-01)
  %mm = call i1 @cq_measure_i1(i1 %p)
  %a = select i1 %b, i32 2, i32 5
  %zz = zext i1 %mm to i32
  %m = call i32 @cq_measure_si32(i32 %a)
  %r = add i32 %m, %zz
  ret i32 %r
}
