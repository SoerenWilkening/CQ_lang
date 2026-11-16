; ModuleID = 'diff_f3.c'
source_filename = "diff_f3.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @f3_ret(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #2
  %4 = and i32 %3, 1
  %5 = icmp eq i32 %4, 0
  br i1 %5, label %14, label %6

6:                                                ; preds = %2, %6
  %7 = phi i32 [ %10, %6 ], [ 2, %2 ]
  %8 = phi i32 [ %11, %6 ], [ %3, %2 ]
  %9 = mul i32 %7, 5
  %10 = add i32 %9, %8
  %11 = lshr i32 %8, 1
  %12 = and i32 %8, 2
  %13 = icmp eq i32 %12, 0
  br i1 %13, label %14, label %6, !llvm.loop !6

14:                                               ; preds = %6, %2
  %15 = phi i32 [ 2, %2 ], [ %10, %6 ]
  ret i32 %15
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @f3_meas(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #2
  %4 = and i32 %3, 1
  %5 = icmp eq i32 %4, 0
  br i1 %5, label %14, label %6

6:                                                ; preds = %2, %6
  %7 = phi i32 [ %10, %6 ], [ 2, %2 ]
  %8 = phi i32 [ %11, %6 ], [ %3, %2 ]
  %9 = mul i32 %7, 5
  %10 = add i32 %9, %8
  %11 = lshr i32 %8, 1
  %12 = and i32 %8, 2
  %13 = icmp eq i32 %12, 0
  br i1 %13, label %14, label %6, !llvm.loop !9

14:                                               ; preds = %6, %2
  %15 = phi i32 [ 2, %2 ], [ %10, %6 ]
  %16 = tail call i32 @cq_measure_ui32(i32 noundef %15) #3
  ret i32 %16
}

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @f3_meas_n(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #2
  %4 = and i32 %3, 1
  %5 = icmp eq i32 %4, 0
  br i1 %5, label %13, label %6

6:                                                ; preds = %2, %6
  %7 = phi i32 [ %10, %6 ], [ 0, %2 ]
  %8 = phi i32 [ %9, %6 ], [ %3, %2 ]
  %9 = lshr i32 %8, 1
  %10 = add i32 %7, 1
  %11 = and i32 %8, 2
  %12 = icmp eq i32 %11, 0
  br i1 %12, label %13, label %6, !llvm.loop !10

13:                                               ; preds = %6, %2
  %14 = phi i32 [ 0, %2 ], [ %10, %6 ]
  %15 = tail call i32 @cq_measure_ui32(i32 noundef %14) #3
  ret i32 %15
}

; Function Attrs: nounwind ssp uwtable
define i32 @f3_rot(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #2
  %4 = and i32 %3, 1
  %5 = icmp eq i32 %4, 0
  br i1 %5, label %13, label %6

6:                                                ; preds = %2, %6
  %7 = phi i32 [ %9, %6 ], [ 2, %2 ]
  %8 = phi i32 [ %10, %6 ], [ %3, %2 ]
  %9 = add i32 %7, %8
  %10 = lshr i32 %8, 1
  %11 = and i32 %8, 2
  %12 = icmp eq i32 %11, 0
  br i1 %12, label %13, label %6, !llvm.loop !11

13:                                               ; preds = %6, %2
  %14 = phi i32 [ 2, %2 ], [ %9, %6 ]
  %15 = tail call i32 @cq_theta_ui32(i32 noundef %14, double noundef %1) #2
  %16 = tail call i32 @cq_measure_ui32(i32 noundef %15) #3
  ret i32 %16
}

; Function Attrs: nounwind ssp uwtable
define i32 @f3_phi(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #2
  %4 = and i32 %3, 1
  %5 = icmp eq i32 %4, 0
  br i1 %5, label %16, label %6

6:                                                ; preds = %2, %6
  %7 = phi i32 [ %9, %6 ], [ 2, %2 ]
  %8 = phi i32 [ %10, %6 ], [ %3, %2 ]
  %9 = add i32 %7, %8
  %10 = lshr i32 %8, 1
  %11 = and i32 %8, 2
  %12 = icmp eq i32 %11, 0
  br i1 %12, label %13, label %6, !llvm.loop !12

13:                                               ; preds = %6
  %14 = and i32 %9, 4
  %15 = icmp eq i32 %14, 0
  br label %16

16:                                               ; preds = %13, %2
  %17 = phi i32 [ %3, %2 ], [ %10, %13 ]
  %18 = phi i1 [ true, %2 ], [ %15, %13 ]
  br i1 %18, label %20, label %19

19:                                               ; preds = %16
  tail call void @cq_phi(double noundef %1) #3
  br label %20

20:                                               ; preds = %19, %16
  %21 = tail call i32 @cq_measure_ui32(i32 noundef %17) #3
  ret i32 %21
}

declare void @cq_phi(double noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @f3_second(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #2
  %4 = and i32 %3, 1
  %5 = icmp eq i32 %4, 0
  br i1 %5, label %6, label %11

6:                                                ; preds = %11, %2
  %7 = phi i32 [ %3, %2 ], [ %15, %11 ]
  %8 = phi i32 [ 0, %2 ], [ %14, %11 ]
  %9 = and i32 %8, 2
  %10 = icmp eq i32 %9, 0
  br i1 %10, label %25, label %18

11:                                               ; preds = %2, %11
  %12 = phi i32 [ %14, %11 ], [ 0, %2 ]
  %13 = phi i32 [ %15, %11 ], [ %3, %2 ]
  %14 = add i32 %12, 3
  %15 = lshr i32 %13, 1
  %16 = and i32 %13, 2
  %17 = icmp eq i32 %16, 0
  br i1 %17, label %6, label %11, !llvm.loop !13

18:                                               ; preds = %6, %18
  %19 = phi i32 [ %22, %18 ], [ 0, %6 ]
  %20 = phi i32 [ %21, %18 ], [ %8, %6 ]
  %21 = lshr i32 %20, 1
  %22 = add i32 %19, %7
  %23 = and i32 %20, 4
  %24 = icmp eq i32 %23, 0
  br i1 %24, label %25, label %18, !llvm.loop !14

25:                                               ; preds = %18, %6
  %26 = phi i32 [ %8, %6 ], [ %21, %18 ]
  %27 = phi i32 [ 0, %6 ], [ %22, %18 ]
  %28 = add i32 %27, %26
  %29 = tail call i32 @cq_measure_ui32(i32 noundef %28) #3
  ret i32 %29
}

; Function Attrs: nounwind ssp uwtable
define i32 @f3_cloop(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %2) #2
  %5 = and i32 %4, 1
  %6 = icmp eq i32 %5, 0
  br i1 %6, label %7, label %11

7:                                                ; preds = %11, %3
  %8 = phi i32 [ 1, %3 ], [ %14, %11 ]
  %9 = and i32 %1, 3
  %10 = icmp eq i32 %9, 0
  br i1 %10, label %18, label %21

11:                                               ; preds = %3, %11
  %12 = phi i32 [ %14, %11 ], [ 1, %3 ]
  %13 = phi i32 [ %15, %11 ], [ %4, %3 ]
  %14 = add i32 %12, %13
  %15 = lshr i32 %13, 1
  %16 = and i32 %13, 2
  %17 = icmp eq i32 %16, 0
  br i1 %17, label %7, label %11, !llvm.loop !15

18:                                               ; preds = %21, %7
  %19 = phi i32 [ %8, %7 ], [ %25, %21 ]
  %20 = tail call i32 @cq_measure_ui32(i32 noundef %19) #3
  ret i32 %20

21:                                               ; preds = %7, %21
  %22 = phi i32 [ %26, %21 ], [ 0, %7 ]
  %23 = phi i32 [ %25, %21 ], [ %8, %7 ]
  %24 = mul i32 %23, 3
  %25 = add i32 %24, %22
  %26 = add nuw nsw i32 %22, 1
  %27 = icmp eq i32 %26, %9
  br i1 %27, label %18, label %21, !llvm.loop !16
}

; Function Attrs: nounwind ssp uwtable
define i32 @f3_two(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #2
  %4 = and i32 %3, 1
  %5 = icmp eq i32 %4, 0
  br i1 %5, label %13, label %6

6:                                                ; preds = %2, %6
  %7 = phi i32 [ %10, %6 ], [ %3, %2 ]
  %8 = phi i32 [ %9, %6 ], [ 1, %2 ]
  %9 = add i32 %7, %8
  %10 = lshr i32 %7, 1
  %11 = and i32 %7, 2
  %12 = icmp eq i32 %11, 0
  br i1 %12, label %13, label %6, !llvm.loop !17

13:                                               ; preds = %6, %2
  %14 = phi i32 [ 1, %2 ], [ %9, %6 ]
  %15 = phi i32 [ %3, %2 ], [ %10, %6 ]
  %16 = tail call i32 @cq_measure_ui32(i32 noundef %14) #3
  %17 = xor i32 %15, %14
  %18 = tail call i32 @cq_measure_ui32(i32 noundef %17) #3
  %19 = add i32 %18, %16
  ret i32 %19
}

; Function Attrs: nounwind ssp uwtable
define i32 @f3_qif(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #2
  %4 = and i32 %3, 1
  %5 = icmp eq i32 %4, 0
  br i1 %5, label %13, label %6

6:                                                ; preds = %2, %6
  %7 = phi i32 [ %9, %6 ], [ 1, %2 ]
  %8 = phi i32 [ %10, %6 ], [ %3, %2 ]
  %9 = add i32 %7, %8
  %10 = lshr i32 %8, 1
  %11 = and i32 %8, 2
  %12 = icmp eq i32 %11, 0
  br i1 %12, label %13, label %6, !llvm.loop !18

13:                                               ; preds = %6, %2
  %14 = phi i32 [ %3, %2 ], [ %10, %6 ]
  %15 = phi i32 [ 1, %2 ], [ %9, %6 ]
  %16 = icmp ugt i32 %15, %14
  %17 = sub i32 %15, %14
  %18 = sub i32 %14, %15
  %19 = select i1 %16, i32 %17, i32 %18
  %20 = tail call i32 @cq_measure_ui32(i32 noundef %19) #3
  ret i32 %20
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
!13 = distinct !{!13, !7, !8}
!14 = distinct !{!14, !7, !8}
!15 = distinct !{!15, !7, !8}
!16 = distinct !{!16, !7, !8}
!17 = distinct !{!17, !7, !8}
!18 = distinct !{!18, !7, !8}
