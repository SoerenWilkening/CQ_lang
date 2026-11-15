; ModuleID = 'loop_two_exits.c'
source_filename = "loop_two_exits.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@g = local_unnamed_addr global i32 0, align 4

; Function Attrs: nounwind ssp uwtable
define i32 @two_exits(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3
  %6 = icmp sgt i32 %2, 0
  br i1 %6, label %7, label %20

7:                                                ; preds = %4
  %8 = tail call i32 @llvm.smax.i32(i32 %5, i32 -1)
  %9 = add i32 %8, 1
  br label %10

10:                                               ; preds = %7, %17
  %11 = phi i32 [ %18, %17 ], [ 0, %7 ]
  %12 = icmp eq i32 %11, %9
  br i1 %12, label %13, label %14

13:                                               ; preds = %10
  tail call void @cq_phi(double noundef 3.000000e-01) #4
  br label %20

14:                                               ; preds = %10
  %15 = icmp eq i32 %11, %3
  br i1 %15, label %16, label %17

16:                                               ; preds = %14
  store i32 1, ptr @g, align 4, !tbaa !6
  br label %20

17:                                               ; preds = %14
  %18 = add nuw nsw i32 %11, 1
  %19 = icmp eq i32 %18, %2
  br i1 %19, label %20, label %10, !llvm.loop !10

20:                                               ; preds = %17, %4, %16, %13
  %21 = phi i32 [ %11, %16 ], [ %11, %13 ], [ 0, %4 ], [ %18, %17 ]
  %22 = tail call i32 @cq_measure_si32(i32 noundef %5) #4
  %23 = add nsw i32 %22, %21
  ret i32 %23
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.smax.i32(i32, i32) #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #3 = { nomerge nounwind }
attributes #4 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !7, i64 0}
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = distinct !{!10, !11, !12}
!11 = !{!"llvm.loop.mustprogress"}
!12 = !{!"llvm.loop.unroll.disable"}
