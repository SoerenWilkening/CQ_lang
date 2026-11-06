; ModuleID = '/Users/sorenwilkening/Desktop/Projects/CQ_lang2/.claude/worktrees/agent-a41713d75845e4fb4/tests/calls/probes/own_loop_after_arm.c'
source_filename = "/Users/sorenwilkening/Desktop/Projects/CQ_lang2/.claude/worktrees/agent-a41713d75845e4fb4/tests/calls/probes/own_loop_after_arm.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@t = local_unnamed_addr global [4 x i32] zeroinitializer, align 16

; Function Attrs: noinline nounwind ssp uwtable
define i32 @r(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = icmp slt i32 %0, 1
  br i1 %3, label %6, label %4

4:                                                ; preds = %2
  %5 = icmp sgt i32 %1, 0
  br i1 %5, label %11, label %8

6:                                                ; preds = %2
  %7 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 1.000000e+00) #3
  br label %20

8:                                                ; preds = %11, %4
  %9 = phi i32 [ 0, %4 ], [ %17, %11 ]
  %10 = tail call i32 @cq_theta_si32(i32 noundef %9, double noundef 5.000000e-01) #3
  br label %20

11:                                               ; preds = %4, %11
  %12 = phi i32 [ %18, %11 ], [ 0, %4 ]
  %13 = phi i32 [ %17, %11 ], [ 0, %4 ]
  %14 = and i32 %12, 1
  %15 = icmp eq i32 %14, 0
  %16 = select i1 %15, i32 5, i32 3
  %17 = add nuw nsw i32 %16, %13
  %18 = add nuw nsw i32 %12, 1
  %19 = icmp eq i32 %18, %1
  br i1 %19, label %8, label %11, !llvm.loop !6

20:                                               ; preds = %8, %6
  %21 = phi i32 [ %7, %6 ], [ %10, %8 ]
  ret i32 %21
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @f(i32 noundef %0) local_unnamed_addr #2 {
  %2 = and i32 %0, 1
  %3 = and i32 %0, 3
  %4 = tail call i32 @r(i32 noundef %2, i32 noundef %3)
  %5 = tail call i32 @cq_measure_si32(i32 noundef %4) #4
  ret i32 %5
}

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
