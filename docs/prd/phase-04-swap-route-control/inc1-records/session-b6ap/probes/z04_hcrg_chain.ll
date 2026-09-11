; H-1: TWO SEQUENTIAL fused regions. Region 1's merge %m1 holds the peeled
; select AND hosts region 2's tainted branch (the hcrg chain); region 1's
; flatten SPLICES + ERASES %m1. Region 2's merge is fused too.
define i32 @main() local_unnamed_addr {
entry:
  %b0 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %c1 = icmp eq i32 %b0, 1
  br i1 %c1, label %m1, label %a1
a1:
  %t1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  br label %m1
m1:
  %b1 = phi i32 [ %t1, %a1 ], [ 0, %entry ]
  %amux = phi i32 [ 5, %a1 ], [ 2, %entry ]
  %c2 = icmp eq i32 %b1, 1
  br i1 %c2, label %m2, label %a2
a2:
  %t2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 9.000000e-01)
  br label %m2
m2:
  %b2 = phi i32 [ %t2, %a2 ], [ 0, %m1 ]
  %dmux = phi i32 [ 7, %a2 ], [ 3, %m1 ]
  %x0 = tail call i32 @cq_measure_si32(i32 noundef %b0)
  %x1 = tail call i32 @cq_measure_si32(i32 noundef %b1)
  %x2 = tail call i32 @cq_measure_si32(i32 noundef %b2)
  %xa = tail call i32 @cq_measure_si32(i32 noundef %amux)
  %xd = tail call i32 @cq_measure_si32(i32 noundef %dmux)
  %s1 = add nsw i32 %x0, %x1
  %s2 = add nsw i32 %s1, %x2
  %s3 = add nsw i32 %s2, %xa
  %s4 = add nsw i32 %s3, %xd
  ret i32 %s4
}
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)
