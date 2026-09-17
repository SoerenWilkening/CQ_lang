declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)

define i32 @slice() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 3.000000e-01) #2
  %3 = icmp eq i32 %1, 5
  br label %hdr

exit:                                             ; preds = %latch
  %m1 = tail call i32 @cq_measure_si32(i32 noundef %merge) #2
  %m2 = tail call i32 @cq_measure_si32(i32 noundef %u) #2
  %sum = add nsw i32 %m2, %m1
  ret i32 %sum

hdr:                                              ; preds = %0, %latch
  %ivphi = phi i32 [ 0, %0 ], [ %ivnext, %latch ]
  %rphi = phi i32 [ %2, %0 ], [ %merge, %latch ]
  br i1 %3, label %arm, label %latch

arm:                                              ; preds = %hdr
  %armt = tail call i32 @cq_theta_si32(i32 noundef %rphi, double noundef 9.000000e-01) #2
  br label %latch

latch:                                            ; preds = %arm, %hdr
  %merge = phi i32 [ %armt, %arm ], [ %rphi, %hdr ]
  %u = add nsw i32 %1, 1
  %ivnext = add nuw nsw i32 %ivphi, 1
  %exitc = icmp eq i32 %ivphi, 0
  br i1 %exitc, label %hdr, label %exit, !llvm.loop !6
}

attributes #0 = { nounwind ssp uwtable }
attributes #2 = { nounwind }

!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
