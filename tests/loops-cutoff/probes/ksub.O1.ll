; ModuleID = 'ksub.c'
source_filename = "ksub.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @ks_phase(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = and i32 %1, 3
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2) #2
  %6 = icmp eq i32 %4, 0
  br label %7

7:                                                ; preds = %21, %3
  %8 = phi i32 [ 0, %3 ], [ %22, %21 ]
  br i1 %6, label %9, label %12

9:                                                ; preds = %12, %7
  %10 = phi i32 [ 0, %7 ], [ %17, %12 ]
  %11 = icmp eq i32 %10, 2
  br i1 %11, label %20, label %21

12:                                               ; preds = %7, %12
  %13 = phi i32 [ %18, %12 ], [ 0, %7 ]
  %14 = phi i32 [ %17, %12 ], [ 0, %7 ]
  %15 = ashr i32 %5, %13
  %16 = and i32 %15, 3
  %17 = add nuw nsw i32 %16, %14
  %18 = add nuw nsw i32 %13, 1
  %19 = icmp eq i32 %18, %4
  br i1 %19, label %9, label %12, !llvm.loop !6

20:                                               ; preds = %9
  tail call void @cq_phi(double noundef %2) #3
  br label %21

21:                                               ; preds = %20, %9
  %22 = add nuw nsw i32 %8, 1
  %23 = shl i32 512, %8
  %24 = and i32 %23, %5
  %25 = icmp eq i32 %24, 0
  br i1 %25, label %26, label %7, !llvm.loop !9

26:                                               ; preds = %21
  %27 = tail call i32 @cq_measure_si32(i32 noundef %22) #3
  ret i32 %27
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

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
!9 = distinct !{!9, !7, !8}
