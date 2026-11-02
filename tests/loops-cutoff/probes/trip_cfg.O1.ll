; ModuleID = 'trip_cfg.c'
source_filename = "trip_cfg.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @tc_branch(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2
  br label %5

5:                                                ; preds = %14, %3
  %6 = phi i32 [ 1, %3 ], [ %17, %14 ]
  %7 = phi i32 [ 0, %3 ], [ %18, %14 ]
  %8 = icmp slt i32 %7, %2
  br i1 %8, label %9, label %12

9:                                                ; preds = %5
  %10 = sub nsw i32 %2, %7
  %11 = sdiv i32 100, %10
  br label %14

12:                                               ; preds = %5
  %13 = mul nuw nsw i32 %7, 5
  br label %14

14:                                               ; preds = %12, %9
  %15 = phi i32 [ %11, %9 ], [ %13, %12 ]
  %16 = mul nsw i32 %6, 3
  %17 = add nsw i32 %15, %16
  %18 = add nuw nsw i32 %7, 1
  %19 = shl i32 2, %7
  %20 = and i32 %19, %4
  %21 = icmp eq i32 %20, 0
  br i1 %21, label %22, label %5, !llvm.loop !6

22:                                               ; preds = %14
  %23 = tail call i32 @cq_measure_si32(i32 noundef %17) #3
  ret i32 %23
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @tc_switch(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2
  %5 = or i32 %2, 1
  br label %6

6:                                                ; preds = %22, %3
  %7 = phi i32 [ 1, %3 ], [ %23, %22 ]
  %8 = phi i32 [ 0, %3 ], [ %24, %22 ]
  %9 = add nsw i32 %8, %2
  %10 = and i32 %9, 3
  switch i32 %10, label %19 [
    i32 0, label %11
    i32 1, label %13
    i32 2, label %17
    i32 3, label %20
  ]

11:                                               ; preds = %6
  %12 = add nsw i32 %7, 7
  br label %22

13:                                               ; preds = %6
  %14 = sdiv i32 %7, 3
  %15 = sdiv i32 100, %5
  %16 = add nsw i32 %15, %14
  br label %22

17:                                               ; preds = %6
  %18 = add nsw i32 %7, -2
  br label %22

19:                                               ; preds = %6
  unreachable

20:                                               ; preds = %6
  %21 = xor i32 %7, 9
  br label %22

22:                                               ; preds = %20, %17, %13, %11
  %23 = phi i32 [ %21, %20 ], [ %18, %17 ], [ %16, %13 ], [ %12, %11 ]
  %24 = add nuw nsw i32 %8, 1
  %25 = shl i32 2, %8
  %26 = and i32 %25, %4
  %27 = icmp eq i32 %26, 0
  br i1 %27, label %28, label %6, !llvm.loop !9

28:                                               ; preds = %22
  %29 = tail call i32 @cq_measure_si32(i32 noundef %23) #3
  ret i32 %29
}

; Function Attrs: nounwind ssp uwtable
define i32 @tc_qswitch(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2
  br label %4

4:                                                ; preds = %18, %2
  %5 = phi i32 [ 1, %2 ], [ %19, %18 ]
  %6 = phi i32 [ 0, %2 ], [ %20, %18 ]
  %7 = add nsw i32 %6, %3
  %8 = and i32 %7, 3
  switch i32 %8, label %15 [
    i32 0, label %9
    i32 1, label %11
    i32 2, label %13
    i32 3, label %16
  ]

9:                                                ; preds = %4
  %10 = add nsw i32 %5, 7
  br label %18

11:                                               ; preds = %4
  %12 = mul nsw i32 %5, 3
  br label %18

13:                                               ; preds = %4
  %14 = add nsw i32 %5, -2
  br label %18

15:                                               ; preds = %4
  unreachable

16:                                               ; preds = %4
  %17 = xor i32 %5, 9
  br label %18

18:                                               ; preds = %16, %13, %11, %9
  %19 = phi i32 [ %17, %16 ], [ %14, %13 ], [ %12, %11 ], [ %10, %9 ]
  %20 = add nuw nsw i32 %6, 1
  %21 = shl i32 2, %6
  %22 = and i32 %21, %3
  %23 = icmp eq i32 %22, 0
  br i1 %23, label %24, label %4, !llvm.loop !10

24:                                               ; preds = %18
  %25 = tail call i32 @cq_measure_si32(i32 noundef %19) #3
  ret i32 %25
}

; Function Attrs: nounwind ssp uwtable
define i32 @tc_phase(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2
  br label %5

5:                                                ; preds = %11, %3
  %6 = phi i32 [ 0, %3 ], [ %12, %11 ]
  %7 = shl nuw i32 1, %6
  %8 = and i32 %7, %2
  %9 = icmp eq i32 %8, 0
  br i1 %9, label %11, label %10

10:                                               ; preds = %5
  tail call void @cq_phi(double noundef 3.750000e-01) #3
  br label %11

11:                                               ; preds = %10, %5
  %12 = add nuw nsw i32 %6, 1
  %13 = shl i32 2, %6
  %14 = and i32 %13, %4
  %15 = icmp eq i32 %14, 0
  br i1 %15, label %16, label %5, !llvm.loop !11

16:                                               ; preds = %11
  %17 = tail call i32 @cq_measure_si32(i32 noundef %4) #3
  ret i32 %17
}

declare void @cq_phi(double noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @tc_nested(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2
  br label %5

5:                                                ; preds = %19, %3
  %6 = phi i32 [ 0, %3 ], [ %20, %19 ]
  %7 = phi i32 [ 0, %3 ], [ %21, %19 ]
  %8 = icmp slt i32 %7, %2
  br i1 %8, label %9, label %19

9:                                                ; preds = %5
  %10 = shl i32 16, %7
  %11 = and i32 %10, %4
  %12 = icmp eq i32 %11, 0
  br i1 %12, label %17, label %13

13:                                               ; preds = %9
  %14 = sub nsw i32 %2, %7
  %15 = sdiv i32 100, %14
  %16 = add nsw i32 %15, %6
  br label %19

17:                                               ; preds = %9
  %18 = add nsw i32 %6, -1
  br label %19

19:                                               ; preds = %13, %17, %5
  %20 = phi i32 [ %16, %13 ], [ %18, %17 ], [ %6, %5 ]
  %21 = add nuw nsw i32 %7, 1
  %22 = shl i32 2, %7
  %23 = and i32 %22, %4
  %24 = icmp eq i32 %23, 0
  br i1 %24, label %25, label %5, !llvm.loop !12

25:                                               ; preds = %19
  %26 = tail call i32 @cq_measure_si32(i32 noundef %20) #3
  ret i32 %26
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
!9 = distinct !{!9, !7, !8}
!10 = distinct !{!10, !7, !8}
!11 = distinct !{!11, !7, !8}
!12 = distinct !{!12, !7, !8}
