; ModuleID = '/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/1dd3c431-0687-4066-b923-d1dfeec82d5a/scratchpad/fallmin/fall2.c'
source_filename = "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/1dd3c431-0687-4066-b923-d1dfeec82d5a/scratchpad/fallmin/fall2.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nofree norecurse nosync nounwind ssp memory(read, argmem: readwrite, inaccessiblemem: none) uwtable
define range(i32 -1, 1) i32 @interp(ptr nocapture noundef readonly %0, i32 noundef %1, ptr nocapture noundef %2) local_unnamed_addr #0 {
  %4 = icmp sgt i32 %1, 0
  br i1 %4, label %5, label %39

5:                                                ; preds = %3, %35
  %6 = phi i32 [ %36, %35 ], [ 0, %3 ]
  %7 = phi ptr [ %37, %35 ], [ %0, %3 ]
  %8 = load i32, ptr %7, align 4, !tbaa !6
  switch i32 %8, label %39 [
    i32 0, label %9
    i32 1, label %22
  ]

9:                                                ; preds = %5
  %10 = getelementptr inbounds i8, ptr %7, i64 8
  %11 = load i32, ptr %10, align 4, !tbaa !11
  %12 = sext i32 %11 to i64
  %13 = getelementptr inbounds i32, ptr %2, i64 %12
  %14 = load i32, ptr %13, align 4, !tbaa !12
  %15 = add nsw i32 %14, 3
  store i32 %15, ptr %13, align 4, !tbaa !12
  %16 = getelementptr inbounds i8, ptr %7, i64 4
  %17 = load i32, ptr %16, align 4, !tbaa !13
  %18 = sext i32 %17 to i64
  %19 = getelementptr inbounds i32, ptr %2, i64 %18
  %20 = load i32, ptr %19, align 4, !tbaa !12
  %21 = icmp sgt i32 %20, 0
  br i1 %21, label %35, label %22

22:                                               ; preds = %9, %5
  %23 = getelementptr inbounds i8, ptr %7, i64 8
  %24 = load i32, ptr %23, align 4, !tbaa !11
  %25 = sext i32 %24 to i64
  %26 = getelementptr inbounds i32, ptr %2, i64 %25
  %27 = load i32, ptr %26, align 4, !tbaa !12
  %28 = add nsw i32 %27, 4
  store i32 %28, ptr %26, align 4, !tbaa !12
  %29 = getelementptr inbounds i8, ptr %7, i64 4
  %30 = load i32, ptr %29, align 4, !tbaa !13
  %31 = sext i32 %30 to i64
  %32 = getelementptr inbounds i32, ptr %2, i64 %31
  %33 = load i32, ptr %32, align 4, !tbaa !12
  %34 = icmp sgt i32 %33, 1
  br i1 %34, label %35, label %39

35:                                               ; preds = %9, %22
  %36 = add nuw nsw i32 %6, 1
  %37 = getelementptr inbounds i8, ptr %7, i64 16
  %38 = icmp eq i32 %36, %1
  br i1 %38, label %39, label %5, !llvm.loop !14

39:                                               ; preds = %35, %22, %5, %3
  %40 = phi i32 [ 0, %3 ], [ 0, %35 ], [ -1, %22 ], [ -1, %5 ]
  ret i32 %40
}

attributes #0 = { nofree norecurse nosync nounwind ssp memory(read, argmem: readwrite, inaccessiblemem: none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !8, i64 0}
!7 = !{!"Op", !8, i64 0, !8, i64 4, !8, i64 8, !8, i64 12}
!8 = !{!"int", !9, i64 0}
!9 = !{!"omnipotent char", !10, i64 0}
!10 = !{!"Simple C/C++ TBAA"}
!11 = !{!7, !8, i64 8}
!12 = !{!8, !8, i64 0}
!13 = !{!7, !8, i64 4}
!14 = distinct !{!14, !15, !16}
!15 = !{!"llvm.loop.mustprogress"}
!16 = !{!"llvm.loop.unroll.disable"}
