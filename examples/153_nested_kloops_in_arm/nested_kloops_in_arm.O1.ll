; ModuleID = 'nested_kloops_in_arm.c'
source_filename = "nested_kloops_in_arm.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @nested_kloops_in_arm(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3, i32 noundef %4, i32 noundef %5) local_unnamed_addr #0 {
  %7 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #2
  %8 = tail call i32 @cq_theta_ui32(i32 noundef %2, double noundef %3) #2
  %9 = icmp ugt i32 %7, %5
  br i1 %9, label %10, label %27

10:                                               ; preds = %6
  %11 = icmp ugt i32 %7, %4
  br i1 %11, label %12, label %29

12:                                               ; preds = %10
  %13 = icmp ugt i32 %8, %4
  br label %14

14:                                               ; preds = %12, %23
  %15 = phi i32 [ 0, %12 ], [ %24, %23 ]
  %16 = phi i32 [ %7, %12 ], [ %25, %23 ]
  br i1 %13, label %17, label %23

17:                                               ; preds = %14, %17
  %18 = phi i32 [ %21, %17 ], [ %8, %14 ]
  %19 = phi i32 [ %20, %17 ], [ %15, %14 ]
  %20 = add i32 %18, %19
  %21 = lshr i32 %18, 1
  %22 = icmp ugt i32 %21, %4
  br i1 %22, label %17, label %23, !llvm.loop !6

23:                                               ; preds = %17, %14
  %24 = phi i32 [ %15, %14 ], [ %20, %17 ]
  %25 = add i32 %16, -1
  %26 = icmp ugt i32 %25, %4
  br i1 %26, label %14, label %29, !llvm.loop !9

27:                                               ; preds = %6
  %28 = add i32 %8, %7
  br label %29

29:                                               ; preds = %23, %10, %27
  %30 = phi i32 [ %28, %27 ], [ 0, %10 ], [ %24, %23 ]
  %31 = tail call i32 @cq_measure_ui32(i32 noundef %30) #3
  ret i32 %31
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #1

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
