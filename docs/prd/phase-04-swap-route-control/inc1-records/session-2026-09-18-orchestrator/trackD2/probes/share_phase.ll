declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare void @cq_phi(double noundef)
declare i32 @cq_measure_si32(i32 noundef)

define i32 @slice() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %3 = icmp eq i32 %1, 5
  %z = zext i1 %3 to i32
  br i1 %3, label %4, label %6

4:                                                ; preds = %0
  tail call void @cq_phi(double noundef 7.000000e-01) #2
  br label %6

6:                                                ; preds = %4, %0
  br i1 %3, label %8, label %10

8:                                                ; preds = %6
  tail call void @cq_phi(double noundef 7.000000e-01) #2
  br label %10

10:                                               ; preds = %8, %6
  %12 = tail call i32 @cq_measure_si32(i32 noundef %z) #2
  %13 = tail call i32 @cq_measure_si32(i32 noundef %1) #2
  %14 = add nsw i32 %13, %12
  ret i32 %14
}

attributes #0 = { nounwind ssp uwtable }
attributes #2 = { nounwind }
