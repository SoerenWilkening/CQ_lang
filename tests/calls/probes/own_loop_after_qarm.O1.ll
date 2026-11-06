; ModuleID = '/Users/sorenwilkening/Desktop/Projects/CQ_lang2/.claude/worktrees/agent-a41713d75845e4fb4/tests/calls/probes/own_loop_after_qarm.c'
source_filename = "/Users/sorenwilkening/Desktop/Projects/CQ_lang2/.claude/worktrees/agent-a41713d75845e4fb4/tests/calls/probes/own_loop_after_qarm.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@tab = local_unnamed_addr global [8 x i32] [i32 3, i32 1, i32 4, i32 1, i32 5, i32 9, i32 2, i32 6], align 16

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483647, -2147483648) i32 @h1(i32 noundef %0) local_unnamed_addr #0 {
  %2 = mul nsw i32 %0, 3
  %3 = add nsw i32 %2, 1
  ret i32 %3
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483646, -2147483648) i32 @h2(i32 noundef %0) local_unnamed_addr #0 {
  %2 = mul nsw i32 %0, 5
  %3 = add nsw i32 %2, 2
  ret i32 %3
}

; Function Attrs: noinline nounwind ssp uwtable
define i32 @r(i32 noundef %0) local_unnamed_addr #1 {
  %2 = and i32 %0, 7
  %3 = zext nneg i32 %2 to i64
  %4 = getelementptr inbounds [8 x i32], ptr @tab, i64 0, i64 %3
  %5 = load i32, ptr %4, align 4, !tbaa !6
  %6 = icmp sgt i32 %5, 3
  br i1 %6, label %7, label %8

7:                                                ; preds = %1
  tail call void @cq_phi(double noundef 3.000000e-01) #4
  br label %8

8:                                                ; preds = %7, %1
  %9 = icmp sgt i32 %0, 0
  br i1 %9, label %14, label %10

10:                                               ; preds = %23, %8
  %11 = phi i32 [ 0, %8 ], [ %24, %23 ]
  %12 = load i32, ptr @tab, align 16, !tbaa !6
  %13 = add nsw i32 %12, %11
  ret i32 %13

14:                                               ; preds = %8, %23
  %15 = phi i32 [ %25, %23 ], [ 0, %8 ]
  %16 = phi i32 [ %24, %23 ], [ 0, %8 ]
  %17 = and i32 %15, 1
  %18 = icmp eq i32 %17, 0
  br i1 %18, label %21, label %19

19:                                               ; preds = %14
  %20 = tail call i32 @h1(i32 noundef %16)
  br label %23

21:                                               ; preds = %14
  %22 = tail call i32 @h2(i32 noundef %16)
  br label %23

23:                                               ; preds = %19, %21
  %24 = phi i32 [ %20, %19 ], [ %22, %21 ]
  %25 = add nuw nsw i32 %15, 1
  %26 = icmp eq i32 %25, %0
  br i1 %26, label %10, label %14, !llvm.loop !10
}

declare void @cq_phi(double noundef) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define i32 @f(i32 noundef %0) local_unnamed_addr #3 {
  %2 = and i32 %0, 3
  %3 = tail call i32 @r(i32 noundef %2)
  %4 = tail call i32 @cq_measure_si32(i32 noundef %3) #4
  ret i32 %4
}

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
