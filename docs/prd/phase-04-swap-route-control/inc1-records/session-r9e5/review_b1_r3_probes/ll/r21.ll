; r21 — CONTROL for r20: the same module with the chained theta moved AFTER the
; `cq_phi` consumer, so it is genuinely after the gate that fires. Must ACCEPT
; on both binaries.
declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
define i1 @main2(i1 %u0) {
entry:
  %b = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  %a = select i1 %b, double 9.000000e-01, double 3.000000e-01
  call void @cq_phi(double %a)
  %b2 = call i1 @cq_theta_i1(i1 %b, double 3.000000e-01)
  %m = call i1 @cq_measure_i1(i1 %b2)
  ret i1 %m
}
