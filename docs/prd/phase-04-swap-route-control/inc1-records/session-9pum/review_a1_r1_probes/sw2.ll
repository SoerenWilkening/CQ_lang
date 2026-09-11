; the br/compare TWIN of sw1 — same program, an icmp instead of a switch.
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %md = call i32 @cq_measure_si32(i32 %q)
  %c = icmp eq i32 %q, 0
  br i1 %c, label %a0, label %merge
a0:
  call void @cq_phi(double 1.000000e-01)
  br label %merge
merge:
  %m = call i32 @cq_measure_si32(i32 %q)
  %s = add i32 %m, %md
  ret i32 %s
}
