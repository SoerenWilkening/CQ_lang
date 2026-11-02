; ModuleID = 'latches.c'
source_filename = "latches.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @ml_continue(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2
  br label %4

4:                                                ; preds = %16, %2
  %5 = phi i32 [ 1, %2 ], [ %17, %16 ]
  %6 = phi i32 [ 0, %2 ], [ %7, %16 ]
  %7 = add nuw nsw i32 %6, 1
  %8 = shl nuw i32 16, %6
  %9 = and i32 %8, %3
  %10 = icmp eq i32 %9, 0
  br i1 %10, label %18, label %11

11:                                               ; preds = %4
  %12 = mul nsw i32 %5, 5
  %13 = add nsw i32 %12, 1
  %14 = and i32 %13, 64
  %15 = icmp eq i32 %14, 0
  br i1 %15, label %16, label %24

16:                                               ; preds = %11, %18
  %17 = phi i32 [ %13, %11 ], [ %20, %18 ]
  br label %4, !llvm.loop !6

18:                                               ; preds = %4
  %19 = mul nsw i32 %5, 3
  %20 = add nsw i32 %7, %19
  %21 = shl nuw i32 2, %6
  %22 = and i32 %21, %3
  %23 = icmp eq i32 %22, 0
  br i1 %23, label %24, label %16

24:                                               ; preds = %18, %11
  %25 = phi i32 [ %13, %11 ], [ %20, %18 ]
  %26 = tail call i32 @cq_measure_si32(i32 noundef %25) #3
  ret i32 %26
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @ml_phase(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2
  %4 = and i32 %3, 1
  %5 = icmp eq i32 %4, 0
  br i1 %5, label %17, label %6

6:                                                ; preds = %2, %13
  %7 = phi i32 [ %8, %13 ], [ 0, %2 ]
  %8 = add nuw nsw i32 %7, 1
  %9 = shl nuw i32 32, %7
  %10 = and i32 %9, %3
  %11 = icmp eq i32 %10, 0
  br i1 %11, label %12, label %13

12:                                               ; preds = %6
  tail call void @cq_phi(double noundef 1.250000e-01) #3
  br label %13

13:                                               ; preds = %12, %6
  %14 = shl nuw i32 2, %7
  %15 = and i32 %14, %3
  %16 = icmp eq i32 %15, 0
  br i1 %16, label %17, label %6, !llvm.loop !8

17:                                               ; preds = %13, %2
  %18 = tail call i32 @cq_measure_si32(i32 noundef %3) #3
  ret i32 %18
}

declare void @cq_phi(double noundef) local_unnamed_addr #1

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
!6 = distinct !{!6, !7}
!7 = !{!"llvm.loop.unroll.disable"}
!8 = distinct !{!8, !9, !7}
!9 = !{!"llvm.loop.mustprogress"}
