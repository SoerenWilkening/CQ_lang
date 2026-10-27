; ModuleID = 'phase_in_kloop.c'
source_filename = "phase_in_kloop.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @phase_in_kloop(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3, double noundef %4) local_unnamed_addr #0 {
  %6 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #2
  %7 = icmp ugt i32 %6, %2
  br i1 %7, label %8, label %18

8:                                                ; preds = %5, %14
  %9 = phi i32 [ %15, %14 ], [ 0, %5 ]
  %10 = phi i32 [ %16, %14 ], [ %6, %5 ]
  %11 = and i32 %10, 1
  %12 = icmp eq i32 %11, 0
  br i1 %12, label %14, label %13

13:                                               ; preds = %8
  tail call void @cq_phi(double noundef %3) #3
  br label %14

14:                                               ; preds = %13, %8
  %15 = tail call i32 @cq_theta_si32(i32 noundef %9, double noundef %4) #2
  %16 = lshr i32 %10, 1
  %17 = icmp ugt i32 %16, %2
  br i1 %17, label %8, label %18, !llvm.loop !6

18:                                               ; preds = %14, %5
  %19 = phi i32 [ %6, %5 ], [ %16, %14 ]
  %20 = phi i32 [ 0, %5 ], [ %15, %14 ]
  %21 = tail call i32 @cq_measure_si32(i32 noundef %20) #3
  %22 = tail call i32 @cq_measure_ui32(i32 noundef %19) #3
  %23 = add i32 %22, %21
  ret i32 %23
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

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
