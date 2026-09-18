; The pure phase kickback on a bare rail — the SHIPPED shape (bd 3qlq.4).
; Regression control: must be unchanged by this increment.
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare void @cq_phi(double)
define i32 @probe() {
entry:
  %b = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  br i1 %b, label %arm, label %merge
arm:
  call void @cq_phi(double 3.140000e+00)
  br label %merge
merge:
  %mb = call i1 @cq_measure_i1(i1 %b)
  %z  = zext i1 %mb to i32
  ret i32 %z
}
