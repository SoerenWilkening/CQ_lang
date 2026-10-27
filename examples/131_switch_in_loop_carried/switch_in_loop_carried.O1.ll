; ModuleID = 'switch_in_loop_carried.c'
source_filename = "switch_in_loop_carried.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @switch_in_loop_carried(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2
  %5 = icmp sgt i32 %2, 0
  br i1 %5, label %9, label %6

6:                                                ; preds = %21, %3
  %7 = phi i32 [ 1, %3 ], [ %22, %21 ]
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #3
  ret i32 %8

9:                                                ; preds = %3, %21
  %10 = phi i32 [ %23, %21 ], [ 0, %3 ]
  %11 = phi i32 [ %22, %21 ], [ 1, %3 ]
  %12 = ashr i32 %4, %10
  %13 = and i32 %12, 3
  switch i32 %13, label %20 [
    i32 0, label %14
    i32 1, label %16
    i32 2, label %18
    i32 3, label %21
  ]

14:                                               ; preds = %9
  %15 = add nsw i32 %10, %11
  br label %21

16:                                               ; preds = %9
  %17 = xor i32 %11, 5
  br label %21

18:                                               ; preds = %9
  %19 = mul nsw i32 %11, 3
  br label %21

20:                                               ; preds = %9
  unreachable

21:                                               ; preds = %14, %16, %18, %9
  %22 = phi i32 [ %11, %9 ], [ %19, %18 ], [ %17, %16 ], [ %15, %14 ]
  %23 = add nuw nsw i32 %10, 1
  %24 = icmp eq i32 %23, %2
  br i1 %24, label %6, label %9, !llvm.loop !6
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

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
