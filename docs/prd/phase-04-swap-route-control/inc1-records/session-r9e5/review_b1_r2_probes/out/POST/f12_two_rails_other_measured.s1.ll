; f12 — TWO INDEPENDENT rails; the OTHER one is measured before the select. The
; closure must not be so wide that it declines (over-decline probe).
declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i64 @cq_theta_si64(i64, double)
declare i64 @cq_measure_si64(i64)
define i32 @main() {
entry:
  %c0 = call i1 @cq_theta_i1(i1 true, double 1.000000e-01)
  %c = call i1 @cq_theta_i1(i1 %c0, double 4.000000e-01)
  %b0 = call i1 @cq_theta_i1(i1 false, double 2.000000e-01)
  %b = call i1 @cq_theta_i1(i1 %b0, double 5.000000e-01)
  %mm = call i1 @cq_measure_i1(i1 %c0)
  %a = select i1 %b, i32 7, i32 9
  %zz = zext i1 %mm to i32
  %m = call i32 @cq_measure_si32(i32 %a)
  %r = add i32 %m, %zz
  ret i32 %r
}
