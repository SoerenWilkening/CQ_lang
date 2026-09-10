; f01 — the rail's parent is a 4.4 SELECT MERGE %out (TAINTED at round 1), and
; that parent name is MEASURED before the second select. The closure must see it.
declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i64 @cq_theta_si64(i64, double)
declare i64 @cq_measure_si64(i64)
define i32 @main() {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 2.000000e-01)
  %cc = icmp eq i32 %q, 1
  %o = select i1 %cc, i32 2, i32 5
  %t = trunc i32 %o to i1
  %b = call i1 @cq_theta_i1(i1 %t, double 5.000000e-01)
  %mm = call i1 @cq_measure_i1(i1 %t)
  %a = select i1 %b, i32 7, i32 9
  %zz = zext i1 %mm to i32
  %m = call i32 @cq_measure_si32(i32 %a)
  %r = add i32 %m, %zz
  ret i32 %r
}
