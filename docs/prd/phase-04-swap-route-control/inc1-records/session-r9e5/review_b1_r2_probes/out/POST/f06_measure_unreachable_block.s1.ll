; f06 — the parent is measured in an UNREACHABLE block. The select must not be
; declined by it (the measure never executes) — an over-decline probe.
declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i64 @cq_theta_si64(i64, double)
declare i64 @cq_measure_si64(i64)
define i32 @main() {
entry:
  %b0 = call i1 @cq_theta_i1(i1 false, double 2.000000e-01)
  %b = call i1 @cq_theta_i1(i1 %b0, double 5.000000e-01)
  %a = select i1 %b, i32 7, i32 9
  %m = call i32 @cq_measure_si32(i32 %a)
  ret i32 %m
dead:
  %mm = call i1 @cq_measure_i1(i1 %b0)
  br label %dead
}
