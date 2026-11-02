; ModuleID = 'c3arm.c'
source_filename = "c3arm.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @arm_branch(ptr nocapture noundef readonly %0, i32 noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef %2) #2
  %5 = icmp sgt i32 %1, 0
  br i1 %5, label %6, label %22

6:                                                ; preds = %3
  %7 = zext nneg i32 %1 to i64
  br label %8

8:                                                ; preds = %6, %19
  %9 = phi i64 [ 0, %6 ], [ %20, %19 ]
  %10 = getelementptr inbounds i32, ptr %0, i64 %9
  %11 = load i32, ptr %10, align 4, !tbaa !6
  %12 = icmp eq i32 %11, %4
  br i1 %12, label %13, label %19

13:                                               ; preds = %8
  %14 = trunc nuw nsw i64 %9 to i32
  %15 = icmp sgt i32 %4, 2
  %16 = shl nuw nsw i32 %14, 1
  %17 = add nuw nsw i32 %14, 7
  %18 = select i1 %15, i32 %16, i32 %17
  br label %22

19:                                               ; preds = %8
  %20 = add nuw nsw i64 %9, 1
  %21 = icmp eq i64 %20, %7
  br i1 %21, label %22, label %8, !llvm.loop !10

22:                                               ; preds = %19, %3, %13
  %23 = phi i32 [ %18, %13 ], [ -1, %3 ], [ -1, %19 ]
  %24 = tail call i32 @cq_measure_si32(i32 noundef %23) #3
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
