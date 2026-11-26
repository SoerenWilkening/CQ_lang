; ModuleID = 'switch_dead.c'
source_filename = "switch_dead.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @sd_goto(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef %2) #2
  %5 = and i32 %0, 64
  %6 = icmp eq i32 %5, 0
  br label %7

7:                                                ; preds = %3, %25
  %8 = phi i32 [ %4, %3 ], [ %26, %25 ]
  %9 = phi i32 [ 0, %3 ], [ %13, %25 ]
  %10 = shl nuw nsw i32 %9, 1
  %11 = ashr i32 %0, %10
  %12 = and i32 %11, 3
  %13 = add nuw nsw i32 %9, 1
  switch i32 %12, label %22 [
    i32 0, label %14
    i32 1, label %16
    i32 2, label %19
    i32 3, label %23
  ]

14:                                               ; preds = %7
  %15 = add nsw i32 %8, 1
  br label %19

16:                                               ; preds = %19, %7
  %17 = phi i32 [ %21, %19 ], [ %8, %7 ]
  %18 = add nsw i32 %17, 5
  br label %25

19:                                               ; preds = %7, %14
  %20 = phi i32 [ %8, %7 ], [ %15, %14 ]
  %21 = xor i32 %20, 2
  br i1 %6, label %25, label %16

22:                                               ; preds = %7
  unreachable

23:                                               ; preds = %7
  %24 = add nsw i32 %8, -1
  br label %25

25:                                               ; preds = %19, %23, %16
  %26 = phi i32 [ %24, %23 ], [ %18, %16 ], [ %21, %19 ]
  %27 = icmp eq i32 %13, 3
  br i1 %27, label %28, label %7, !llvm.loop !6

28:                                               ; preds = %25
  %29 = tail call i32 @cq_measure_si32(i32 noundef %26) #3
  ret i32 %29
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
