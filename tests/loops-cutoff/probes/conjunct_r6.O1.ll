; ModuleID = 'conjunct_r6.c'
source_filename = "conjunct_r6.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @cr_meas(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #2
  %5 = and i32 %2, 1
  %6 = icmp ne i32 %5, 0
  %7 = icmp ugt i32 %4, 2
  %8 = select i1 %6, i1 %7, i1 false
  br i1 %8, label %9, label %25

9:                                                ; preds = %3, %9
  %10 = phi i32 [ %17, %9 ], [ 0, %3 ]
  %11 = phi i32 [ %16, %9 ], [ 0, %3 ]
  %12 = phi i32 [ %13, %9 ], [ %4, %3 ]
  %13 = add i32 %12, -3
  %14 = and i32 %13, 1
  %15 = tail call i32 @cq_measure_ui32(i32 noundef %14) #3
  %16 = add i32 %15, %11
  %17 = add nuw nsw i32 %10, 1
  %18 = shl nuw i32 2, %10
  %19 = and i32 %18, %2
  %20 = icmp ne i32 %19, 0
  %21 = icmp ugt i32 %13, 2
  %22 = and i1 %20, %21
  br i1 %22, label %9, label %23, !llvm.loop !6

23:                                               ; preds = %9
  %24 = shl i32 %16, 8
  br label %25

25:                                               ; preds = %23, %3
  %26 = phi i32 [ %4, %3 ], [ %13, %23 ]
  %27 = phi i32 [ 0, %3 ], [ %24, %23 ]
  %28 = tail call i32 @cq_measure_ui32(i32 noundef %26) #3
  %29 = add i32 %28, %27
  ret i32 %29
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @cr_shift(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #2
  %5 = and i32 %2, 1
  %6 = icmp ne i32 %5, 0
  %7 = icmp ugt i32 %4, 2
  %8 = select i1 %6, i1 %7, i1 false
  br i1 %8, label %9, label %26

9:                                                ; preds = %3, %9
  %10 = phi i32 [ %18, %9 ], [ 0, %3 ]
  %11 = phi i32 [ %17, %9 ], [ 0, %3 ]
  %12 = phi i32 [ %14, %9 ], [ %4, %3 ]
  %13 = lshr i32 %12, 1
  %14 = xor i32 %13, 5
  %15 = and i32 %14, 1
  %16 = tail call i32 @cq_measure_ui32(i32 noundef %15) #3
  %17 = add i32 %16, %11
  %18 = add i32 %10, 1
  %19 = shl nuw i32 1, %18
  %20 = and i32 %19, %2
  %21 = icmp ne i32 %20, 0
  %22 = icmp ugt i32 %14, 2
  %23 = and i1 %21, %22
  br i1 %23, label %9, label %24, !llvm.loop !9

24:                                               ; preds = %9
  %25 = shl i32 %17, 8
  br label %26

26:                                               ; preds = %24, %3
  %27 = phi i32 [ %4, %3 ], [ %14, %24 ]
  %28 = phi i32 [ 0, %3 ], [ %25, %24 ]
  %29 = tail call i32 @cq_measure_ui32(i32 noundef %27) #3
  %30 = add i32 %29, %28
  ret i32 %30
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
