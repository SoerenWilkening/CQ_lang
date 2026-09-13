define i32 @main() local_unnamed_addr #0 {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2
  br i1 %1, label %4, label %2

2:                                                ; preds = %0
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2
  br label %4

4:                                                ; preds = %2, %0
  %5 = phi i32 [ 5, %2 ], [ 2, %0 ]
  %6 = phi i1 [ %3, %2 ], [ false, %0 ]
  %7 = add nsw i32 %5, -3
  %8 = select i1 %6, i32 %7, i32 %5
  %9 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %1) #2
  %10 = zext i1 %9 to i32
  %11 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %6) #2
  %12 = zext i1 %11 to i32
  %13 = add nuw nsw i32 %12, %10
  %14 = tail call i32 @cq_measure_si32(i32 noundef %8) #2
  %15 = add nsw i32 %13, %14
  ret i32 %15
}
