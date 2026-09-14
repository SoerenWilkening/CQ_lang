; ModuleID = 'src/rc7_two_flags_and.c'
source_filename = "src/rc7_two_flags_and.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @example(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 2.500000e-01) #2
  %3 = icmp sgt i32 %0, 2
  br label %5

4:                                                ; preds = %13
  ret i32 %15

5:                                                ; preds = %1, %13
  %6 = phi i32 [ 0, %1 ], [ %15, %13 ]
  %7 = phi i32 [ 0, %1 ], [ %16, %13 ]
  %8 = icmp eq i32 %7, 0
  %9 = and i1 %3, %8
  br i1 %9, label %10, label %13

10:                                               ; preds = %5
  %11 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 9.000000e-01) #2
  %12 = tail call i32 @cq_measure_si32(i32 noundef %11) #2
  br label %13

13:                                               ; preds = %5, %10
  %14 = phi i32 [ %12, %10 ], [ 1, %5 ]
  %15 = add nsw i32 %14, %6
  %16 = add nuw nsw i32 %7, 1
  %17 = icmp eq i32 %16, 4
  br i1 %17, label %4, label %5, !llvm.loop !6
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind }

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
