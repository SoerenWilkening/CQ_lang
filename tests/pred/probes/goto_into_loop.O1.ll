; ModuleID = 'goto_into_loop.c'
source_filename = "goto_into_loop.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @h(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 1.000000e+00) #2
  %4 = and i32 %3, 3
  %5 = and i32 %1, 3
  %6 = icmp eq i32 %5, 1
  %7 = select i1 %6, i32 11, i32 0
  %8 = icmp eq i32 %5, 0
  %9 = select i1 %8, i32 7, i32 %7
  %10 = and i32 %3, 4
  %11 = icmp eq i32 %10, 0
  br i1 %11, label %12, label %18

12:                                               ; preds = %2, %18
  %13 = phi i32 [ %21, %18 ], [ %9, %2 ]
  %14 = phi i32 [ %22, %18 ], [ %4, %2 ]
  %15 = icmp sgt i32 %14, 0
  br i1 %15, label %16, label %23

16:                                               ; preds = %12
  %17 = add nsw i32 %13, 1
  br label %18

18:                                               ; preds = %2, %16
  %19 = phi i32 [ %9, %2 ], [ %17, %16 ]
  %20 = phi i32 [ %4, %2 ], [ %14, %16 ]
  %21 = add nsw i32 %19, 2
  %22 = add nsw i32 %20, -1
  br label %12, !llvm.loop !6

23:                                               ; preds = %12
  %24 = tail call i32 @cq_measure_si32(i32 noundef %13) #3
  ret i32 %24
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 2]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
