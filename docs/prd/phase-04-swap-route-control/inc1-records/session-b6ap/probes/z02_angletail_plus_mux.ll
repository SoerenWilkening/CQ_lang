; 2 phis: the phaseAngleTail (an ANGLE) BESIDE an int data mux.
define i32 @main() local_unnamed_addr {
entry:
  %b0 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %c = icmp eq i32 %b0, 1
  br i1 %c, label %merge, label %arm
arm:
  br label %merge
merge:
  %ang = phi double [ 9.000000e-01, %arm ], [ 3.000000e-01, %entry ]
  %amux = phi i32 [ 5, %arm ], [ 2, %entry ]
  tail call void @cq_phi(double noundef %ang)
  %m0 = tail call i32 @cq_measure_si32(i32 noundef %b0)
  %ma = tail call i32 @cq_measure_si32(i32 noundef %amux)
  %s = add nsw i32 %m0, %ma
  ret i32 %s
}
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare void @cq_phi(double noundef)
declare i32 @cq_measure_si32(i32 noundef)
