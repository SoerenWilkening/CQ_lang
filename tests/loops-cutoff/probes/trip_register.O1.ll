; ModuleID = 'trip_register.c'
source_filename = "trip_register.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @w_d(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4) local_unnamed_addr #0 {
  %6 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #2
  %7 = tail call i32 @cq_theta_ui32(i32 noundef %4, double noundef %1) #2
  %8 = icmp ugt i32 %6, %2
  br i1 %8, label %9, label %21

9:                                                ; preds = %5
  %10 = and i32 %3, 2
  %11 = icmp eq i32 %10, 0
  br label %12

12:                                               ; preds = %9, %18
  %13 = phi i32 [ %7, %9 ], [ %19, %18 ]
  %14 = phi i32 [ %6, %9 ], [ %15, %18 ]
  %15 = lshr i32 %14, 1
  br i1 %11, label %18, label %16

16:                                               ; preds = %12
  %17 = tail call i32 @cq_theta_ui32(i32 noundef %13, double noundef 2.500000e-01) #2
  br label %18

18:                                               ; preds = %16, %12
  %19 = phi i32 [ %17, %16 ], [ %13, %12 ]
  %20 = icmp ugt i32 %15, %2
  br i1 %20, label %12, label %21, !llvm.loop !6

21:                                               ; preds = %18, %5
  %22 = phi i32 [ %7, %5 ], [ %19, %18 ]
  %23 = tail call i32 @cq_measure_ui32(i32 noundef %22) #3
  ret i32 %23
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @w_e(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4) local_unnamed_addr #0 {
  %6 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #2
  %7 = tail call i32 @cq_theta_ui32(i32 noundef %4, double noundef %1) #2
  %8 = icmp ugt i32 %6, %2
  br i1 %8, label %9, label %23

9:                                                ; preds = %5
  %10 = and i32 %3, 2
  %11 = icmp eq i32 %10, 0
  br label %12

12:                                               ; preds = %9, %20
  %13 = phi i32 [ %7, %9 ], [ %21, %20 ]
  %14 = phi i32 [ %6, %9 ], [ %15, %20 ]
  %15 = lshr i32 %14, 1
  br i1 %11, label %18, label %16

16:                                               ; preds = %12
  %17 = tail call i32 @cq_theta_ui32(i32 noundef %13, double noundef 2.500000e-01) #2
  br label %20

18:                                               ; preds = %12
  %19 = tail call i32 @cq_theta_ui32(i32 noundef %13, double noundef 5.000000e-01) #2
  br label %20

20:                                               ; preds = %18, %16
  %21 = phi i32 [ %17, %16 ], [ %19, %18 ]
  %22 = icmp ugt i32 %15, %2
  br i1 %22, label %12, label %23, !llvm.loop !9

23:                                               ; preds = %20, %5
  %24 = phi i32 [ %7, %5 ], [ %21, %20 ]
  %25 = tail call i32 @cq_measure_ui32(i32 noundef %24) #3
  ret i32 %25
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
