define i32 @main() local_unnamed_addr {
entry:
  %b0 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %r0 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 3.000000e-01)
  %c1 = icmp eq i32 %b0, 1
  %c2 = icmp eq i32 %r0, 3
  %c = and i1 %c1, %c2
  br i1 %c, label %m, label %a
a:
  %t = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  br label %m
m:
  %b1 = phi i32 [ %t, %a ], [ 0, %entry ]
  %mux = phi i32 [ 5, %a ], [ 2, %entry ]
  %x0 = tail call i32 @cq_measure_si32(i32 noundef %b1)
  %x1 = tail call i32 @cq_measure_si32(i32 noundef %mux)
  %s = add nsw i32 %x0, %x1
  ret i32 %s
}
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)
