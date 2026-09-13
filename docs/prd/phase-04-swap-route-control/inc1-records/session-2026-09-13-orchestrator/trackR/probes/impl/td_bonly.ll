define i32 @main() local_unnamed_addr {
entry:
  %q  = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %g  = icmp sgt i32 %q, 5
  br i1 %g, label %armB, label %mB
armB:
  %tb = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  br label %mB
mB:
  %pb = phi i32 [ %tb, %armB ], [ 0, %entry ]
  %mx = phi i32 [ 2, %armB ], [ 5, %entry ]
  %m0 = tail call i32 @cq_measure_si32(i32 noundef %q)
  %m2 = tail call i32 @cq_measure_si32(i32 noundef %pb)
  %m3 = tail call i32 @cq_measure_si32(i32 noundef %mx)
  %s2 = add nsw i32 %m0, %m2
  %s3 = add nsw i32 %s2, %m3
  ret i32 %s3
}
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32)
