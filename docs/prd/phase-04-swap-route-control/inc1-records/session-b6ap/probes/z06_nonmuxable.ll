define i32 @main() local_unnamed_addr {
entry:
  %b0 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %c = icmp eq i32 %b0, 1
  br i1 %c, label %m, label %a
a:
  %t = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  br label %m
m:
  %b1 = phi i32 [ %t, %a ], [ 0, %entry ]
  %w = phi i128 [ 5, %a ], [ 2, %entry ]
  %wt = trunc i128 %w to i32
  %x0 = tail call i32 @cq_measure_si32(i32 noundef %b1)
  %s = add nsw i32 %x0, %wt
  ret i32 %s
}
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)
