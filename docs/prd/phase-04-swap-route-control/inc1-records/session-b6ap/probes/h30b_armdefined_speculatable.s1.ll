; 2-phi merge: one phi's arm incoming is a SPECULATABLE op DEFINED IN THE ARM
; (the peel must not hoist it) beside the region's own state-prep phi.
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"
define i32 @main() local_unnamed_addr #0 {
entry:
  %b0 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %c = icmp sgt i32 %b0, 3
  br i1 %c, label %arm, label %merge

arm:
  %t1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %d = mul nsw i32 %b0, 7
  br label %merge

merge:
  %b1 = phi i32 [ %t1, %arm ], [ 0, %entry ]
  %s = phi i32 [ %d, %arm ], [ 0, %entry ]
  %m0 = tail call i32 @cq_measure_si32(i32 noundef %b0) #2
  %m1 = tail call i32 @cq_measure_si32(i32 noundef %b1) #2
  %m2 = tail call i32 @cq_measure_si32(i32 noundef %s) #2
  %x1 = add nsw i32 %m0, %m1
  %x2 = add nsw i32 %x1, %m2
  ret i32 %x2
}
declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1
declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1
attributes #0 = { nounwind ssp uwtable }
attributes #1 = { nounwind }
attributes #2 = { nounwind }
