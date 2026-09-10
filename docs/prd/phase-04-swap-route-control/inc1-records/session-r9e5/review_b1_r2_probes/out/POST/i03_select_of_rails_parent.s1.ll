; i03 — the rail's parent is a SELECT OF RAILS (a live classical mux over two
; registers). Expect a loud decline somewhere (no-cloning / classical mux).
@g = global i1 false
declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @main() {
entry:
  %p = call i1 @cq_theta_i1(i1 false, double 2.000000e-01)
  %r = call i1 @cq_theta_i1(i1 true, double 3.000000e-01)
  %g = load volatile i1, ptr @g
  %x = select i1 %g, i1 %p, i1 %r
  %b = call i1 @cq_theta_i1(i1 %x, double 5.000000e-01)
  %mm = call i1 @cq_measure_i1(i1 %p)
  %a = select i1 %b, i32 2, i32 5
  %m = call i32 @cq_measure_si32(i32 %a)
  ret i32 %m
}
