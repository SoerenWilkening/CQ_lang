declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)

define i32 @slice() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 3.000000e-01) #2
  %s0 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 2.000000e-01) #2
  %3 = icmp eq i32 %1, 5
  br label %8

4:                                                ; preds = %13
  %5 = tail call i32 @cq_measure_si32(i32 noundef %14) #2
  %6 = tail call i32 @cq_measure_si32(i32 noundef %15) #2
  %7 = add nsw i32 %6, %5
  ret i32 %7

8:                                                ; preds = %0, %13
  %9 = phi i32 [ 0, %0 ], [ %16, %13 ]
  %10 = phi i32 [ %2, %0 ], [ %14, %13 ]
  br i1 %3, label %11, label %13

11:                                               ; preds = %8
  %12 = tail call i32 @cq_theta_si32(i32 noundef %10, double noundef 9.000000e-01) #2
  br label %13

13:                                               ; preds = %11, %8
  %14 = phi i32 [ %12, %11 ], [ %10, %8 ]
  %15 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 1.000000e-01) #2
  %16 = add nuw nsw i32 %9, 1
  %17 = icmp eq i32 %9, 0
  br i1 %17, label %8, label %4, !llvm.loop !6
}

attributes #0 = { nounwind ssp uwtable }
attributes #2 = { nounwind }

!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
