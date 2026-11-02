; ModuleID = 'partial_measure.c'
source_filename = "partial_measure.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @pm_ret(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 1.000000e+00) #2
  %4 = mul nsw i32 %3, 3
  %5 = icmp eq i32 %1, 0
  br i1 %5, label %9, label %6

6:                                                ; preds = %2
  %7 = add nsw i32 %4, 1
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #3
  br label %14

9:                                                ; preds = %2
  %10 = tail call i32 @cq_measure_si32(i32 noundef %3) #3
  %11 = and i32 %4, 1
  %12 = tail call i32 @cq_measure_si32(i32 noundef %11) #3
  %13 = add nsw i32 %12, %10
  br label %14

14:                                               ; preds = %9, %6
  %15 = phi i32 [ %8, %6 ], [ %13, %9 ]
  ret i32 %15
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @pm_join(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 1.000000e+00) #2
  %4 = add nsw i32 %3, 7
  %5 = icmp eq i32 %1, 0
  br i1 %5, label %8, label %6

6:                                                ; preds = %2
  %7 = tail call i32 @cq_measure_si32(i32 noundef %4) #3
  br label %8

8:                                                ; preds = %6, %2
  %9 = phi i32 [ %7, %6 ], [ 0, %2 ]
  %10 = mul nsw i32 %4, 3
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #3
  %12 = add nsw i32 %11, %9
  ret i32 %12
}

; Function Attrs: nounwind ssp uwtable
define i32 @pm_loop(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 1.000000e+00) #2
  %4 = icmp sgt i32 %1, 0
  br i1 %4, label %7, label %5

5:                                                ; preds = %16, %2
  %6 = phi i32 [ 0, %2 ], [ %20, %16 ]
  ret i32 %6

7:                                                ; preds = %2, %16
  %8 = phi i32 [ %21, %16 ], [ 0, %2 ]
  %9 = phi i32 [ %20, %16 ], [ 0, %2 ]
  %10 = add nsw i32 %8, %3
  %11 = and i32 %8, 1
  %12 = icmp eq i32 %11, 0
  br i1 %12, label %16, label %13

13:                                               ; preds = %7
  %14 = tail call i32 @cq_measure_si32(i32 noundef %10) #3
  %15 = add nsw i32 %14, %9
  br label %16

16:                                               ; preds = %13, %7
  %17 = phi i32 [ %15, %13 ], [ %9, %7 ]
  %18 = and i32 %10, 3
  %19 = tail call i32 @cq_measure_si32(i32 noundef %18) #3
  %20 = add nsw i32 %19, %17
  %21 = add nuw nsw i32 %8, 1
  %22 = icmp eq i32 %21, %1
  br i1 %22, label %5, label %7, !llvm.loop !6
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
