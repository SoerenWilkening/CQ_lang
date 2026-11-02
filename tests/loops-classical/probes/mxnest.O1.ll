; ModuleID = 'mxnest.c'
source_filename = "mxnest.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @mx_nest(ptr nocapture noundef readonly %0, i32 noundef %1, i32 noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef %3) #2
  %6 = icmp sgt i32 %2, 0
  br i1 %6, label %7, label %13

7:                                                ; preds = %4
  %8 = icmp sgt i32 %1, 0
  %9 = zext nneg i32 %1 to i64
  br label %10

10:                                               ; preds = %7, %27
  %11 = phi i32 [ 0, %7 ], [ %30, %27 ]
  %12 = phi i32 [ 0, %7 ], [ %29, %27 ]
  br i1 %8, label %16, label %27

13:                                               ; preds = %27, %4
  %14 = phi i32 [ 0, %4 ], [ %29, %27 ]
  %15 = tail call i32 @cq_measure_si32(i32 noundef %14) #3
  ret i32 %15

16:                                               ; preds = %10, %22
  %17 = phi i64 [ %23, %22 ], [ 0, %10 ]
  %18 = getelementptr inbounds i32, ptr %0, i64 %17
  %19 = load i32, ptr %18, align 4, !tbaa !6
  %20 = add nsw i32 %19, %11
  %21 = icmp eq i32 %20, %5
  br i1 %21, label %25, label %22

22:                                               ; preds = %16
  %23 = add nuw nsw i64 %17, 1
  %24 = icmp eq i64 %23, %9
  br i1 %24, label %27, label %16, !llvm.loop !10

25:                                               ; preds = %16
  %26 = trunc nuw nsw i64 %17 to i32
  br label %27

27:                                               ; preds = %25, %22, %10
  %28 = phi i32 [ -1, %10 ], [ %26, %25 ], [ -1, %22 ]
  %29 = add nsw i32 %28, %12
  %30 = add nuw nsw i32 %11, 1
  %31 = icmp eq i32 %30, %2
  br i1 %31, label %13, label %10, !llvm.loop !13
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
!13 = distinct !{!13, !11, !12}
