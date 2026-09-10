; i01 — the COMPARE TWIN of d01 (the dead borrow chain left allocated). If it
; behaves identically the leak is the spine's, not the rail path's.
declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @main() {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %cc = icmp eq i32 %q, 1
  %a = select i1 %cc, i32 2, i32 5
  %z = and i32 %q, 1
  %s = add i32 %z, 1
  %m = call i32 @cq_measure_si32(i32 %a)
  ret i32 %m
}
