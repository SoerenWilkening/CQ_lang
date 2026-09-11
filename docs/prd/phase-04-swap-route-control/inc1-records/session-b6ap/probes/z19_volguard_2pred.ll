@g = internal global i32 0
define i32 @main() local_unnamed_addr {
entry:
  %k = load volatile i32, ptr @g, align 4
  %kc = icmp eq i32 %k, 9
  br i1 %kc, label %p, label %p2
p2:
  br label %p
p:
  %b0 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %c = icmp eq i32 %b0, 1
  br i1 %c, label %m, label %a
a:
  %t = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  br label %m
m:
  %b1 = phi i32 [ %t, %a ], [ 0, %p ]
  %mux = phi i32 [ 5, %a ], [ 2, %p ]
  %x1 = tail call i32 @cq_measure_si32(i32 noundef %b1)
  %s = add nsw i32 %x1, %mux
  ret i32 %s
}
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)
