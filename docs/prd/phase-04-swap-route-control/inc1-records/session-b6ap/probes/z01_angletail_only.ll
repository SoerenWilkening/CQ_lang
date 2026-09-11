; 1 phi: the phaseAngleTail (an ANGLE). Must be BYTE-UNCHANGED by the peel.
define i32 @main() local_unnamed_addr {
entry:
  %b0 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %c = icmp eq i32 %b0, 1
  br i1 %c, label %merge, label %arm
arm:
  br label %merge
merge:
  %ang = phi double [ 9.000000e-01, %arm ], [ 3.000000e-01, %entry ]
  tail call void @cq_phi(double noundef %ang)
  %m0 = tail call i32 @cq_measure_si32(i32 noundef %b0)
  ret i32 %m0
}
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare void @cq_phi(double noundef)
declare i32 @cq_measure_si32(i32 noundef)
