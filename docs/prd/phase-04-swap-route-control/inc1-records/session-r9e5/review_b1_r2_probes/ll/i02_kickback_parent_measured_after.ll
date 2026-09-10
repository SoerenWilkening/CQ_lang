; i02 — the widened helper at the KICKBACK caller, benign direction: the parent
; name is measured AFTER the branch. Must still ACCEPT (over-decline probe).
declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @main() {
entry:
  %b0 = call i1 @cq_theta_i1(i1 false, double 2.000000e-01)
  %b = call i1 @cq_theta_i1(i1 %b0, double 5.000000e-01)
  br i1 %b, label %ph, label %join
ph:
  call void @cq_phi(double 7.000000e-01)
  br label %join
join:
  %mm = call i1 @cq_measure_i1(i1 %b0)
  %zz = zext i1 %mm to i32
  ret i32 %zz
}
