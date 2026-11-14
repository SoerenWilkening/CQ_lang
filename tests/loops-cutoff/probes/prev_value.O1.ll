; ModuleID = 'prev_value.c'
source_filename = "prev_value.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @prev_value(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2
  br label %6

6:                                                ; preds = %6, %4
  %7 = phi i32 [ %5, %4 ], [ %12, %6 ]
  %8 = phi i32 [ 0, %4 ], [ %7, %6 ]
  %9 = phi i32 [ 0, %4 ], [ %10, %6 ]
  %10 = add nsw i32 %9, %8
  %11 = mul nsw i32 %7, %2
  %12 = add nsw i32 %11, %3
  %13 = icmp sgt i32 %12, 7
  br i1 %13, label %6, label %14, !llvm.loop !6

14:                                               ; preds = %6
  %15 = tail call i32 @cq_measure_si32(i32 noundef %7) #3
  %16 = mul nsw i32 %15, 1000
  %17 = tail call i32 @cq_measure_si32(i32 noundef %12) #3
  %18 = mul nsw i32 %17, 10
  %19 = add nsw i32 %18, %16
  %20 = tail call i32 @cq_measure_si32(i32 noundef %10) #3
  %21 = add nsw i32 %19, %20
  ret i32 %21
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
