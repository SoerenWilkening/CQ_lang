declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)

define i32 @slice() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 3.000000e-01) #2
  %3 = icmp eq i32 %1, 5
  br label %8

4:                                                ; preds = %13
  %post = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 1.000000e-01) #2
  %5 = tail call i32 @cq_measure_si32(i32 noundef %merge) #2
  %6 = tail call i32 @cq_measure_si32(i32 noundef %post) #2
  %7 = add nsw i32 %6, %5
  ret i32 %7

8:                                                ; preds = %0, %13
  %ivphi = phi i32 [ 0, %0 ], [ %ivnext, %13 ]
  %rphi = phi i32 [ %2, %0 ], [ %merge, %13 ]
  br i1 %3, label %11, label %13

11:                                               ; preds = %8
  %armt = tail call i32 @cq_theta_si32(i32 noundef %rphi, double noundef 9.000000e-01) #2
  br label %13

13:                                               ; preds = %11, %8
  %merge = phi i32 [ %armt, %11 ], [ %rphi, %8 ]
  %ivnext = add nuw nsw i32 %ivphi, 1
  %exitc = icmp eq i32 %ivphi, 0
  br i1 %exitc, label %8, label %4, !llvm.loop !6
}

attributes #0 = { nounwind ssp uwtable }
attributes #2 = { nounwind }

!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
