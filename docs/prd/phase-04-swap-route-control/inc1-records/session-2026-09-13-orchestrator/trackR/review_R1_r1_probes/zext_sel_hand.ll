; ITEM 5, hand-IR (the plain-C spelling const-folds away): the peeled i1 SELECT
; zero-extended to i32 and pinned to the i32 prep seed 0 on the TRUE edge.
; The zext is NOT a clone and is NOT excluded -> must stay a DECLINE on both.
define i32 @main() local_unnamed_addr {
entry:
  %q = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %c = icmp eq i32 %q, 1
  %y = icmp sgt i32 %q, 7
  br i1 %c, label %arm, label %m
arm:
  %t = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  br label %m
m:
  %z  = phi i32 [ %t, %arm ], [ 0, %entry ]
  %mx = phi i1  [ %y, %arm ], [ false, %entry ]
  %zu = zext i1 %mx to i32
  %m0 = tail call i32 @cq_measure_si32(i32 noundef %q)
  %m1 = tail call i32 @cq_measure_si32(i32 noundef %z)
  %m2 = tail call i32 @cq_measure_si32(i32 noundef %zu)
  %s1 = add nsw i32 %m0, %m1
  %s2 = add nsw i32 %s1, %m2
  ret i32 %s2
}
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32)
