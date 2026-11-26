; ModuleID = 'join_earlier.c'
source_filename = "join_earlier.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @je_start(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #2
  %4 = and i32 %3, 3
  %5 = lshr i32 %3, 2
  %6 = and i32 %5, 7
  %7 = and i32 %3, 32
  %8 = icmp eq i32 %7, 0
  %9 = icmp eq i32 %4, 0
  br i1 %8, label %11, label %10

10:                                               ; preds = %2
  br i1 %9, label %29, label %20

11:                                               ; preds = %2
  br i1 %9, label %29, label %12

12:                                               ; preds = %11, %12
  %13 = phi i32 [ %15, %12 ], [ %6, %11 ]
  %14 = phi i32 [ %18, %12 ], [ %4, %11 ]
  %15 = phi i32 [ %17, %12 ], [ 1, %11 ]
  %16 = mul i32 %14, %15
  %17 = add i32 %16, %13
  %18 = add nsw i32 %14, -1
  %19 = icmp eq i32 %18, 0
  br i1 %19, label %29, label %12, !llvm.loop !6

20:                                               ; preds = %10, %20
  %21 = phi i32 [ %25, %20 ], [ %6, %10 ]
  %22 = phi i32 [ %27, %20 ], [ %4, %10 ]
  %23 = phi i32 [ %26, %20 ], [ %6, %10 ]
  %24 = mul i32 %21, 5
  %25 = add i32 %24, %23
  %26 = add i32 %21, %22
  %27 = add nsw i32 %22, -1
  %28 = icmp eq i32 %27, 0
  br i1 %28, label %29, label %20, !llvm.loop !9

29:                                               ; preds = %20, %12, %10, %11
  %30 = phi i32 [ 1, %11 ], [ 1, %10 ], [ %17, %12 ], [ 1, %20 ]
  %31 = phi i32 [ %6, %11 ], [ %6, %10 ], [ %15, %12 ], [ %26, %20 ]
  %32 = phi i32 [ %6, %11 ], [ %6, %10 ], [ %6, %12 ], [ %25, %20 ]
  %33 = shl i32 %32, 6
  %34 = shl i32 %31, 2
  %35 = add i32 %34, %30
  %36 = add i32 %35, %33
  %37 = tail call i32 @cq_measure_ui32(i32 noundef %36) #3
  ret i32 %37
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
