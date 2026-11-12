; ModuleID = 'me_carried.c'
source_filename = "me_carried.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @measure_carried(i32 noundef %0, i32 noundef %1, double noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %2) #2
  %6 = tail call i32 @cq_theta_ui32(i32 noundef %1, double noundef %2) #2
  %7 = icmp ugt i32 %5, %3
  br i1 %7, label %8, label %16

8:                                                ; preds = %4, %8
  %9 = phi i32 [ %13, %8 ], [ 0, %4 ]
  %10 = phi i32 [ %6, %8 ], [ %5, %4 ]
  %11 = phi i32 [ %14, %8 ], [ %5, %4 ]
  %12 = tail call i32 @cq_measure_ui32(i32 noundef %10) #3
  %13 = add i32 %12, %9
  %14 = lshr i32 %11, 1
  %15 = icmp ugt i32 %14, %3
  br i1 %15, label %8, label %16, !llvm.loop !6

16:                                               ; preds = %8, %4
  %17 = phi i32 [ 0, %4 ], [ %13, %8 ]
  ret i32 %17
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
