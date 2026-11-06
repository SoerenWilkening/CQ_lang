; ModuleID = '/Users/sorenwilkening/Desktop/Projects/CQ_lang2/.claude/worktrees/agent-adaaa90a106d20464/tests/calls/probes/rec_bus_pair.c'
source_filename = "/Users/sorenwilkening/Desktop/Projects/CQ_lang2/.claude/worktrees/agent-adaaa90a106d20464/tests/calls/probes/rec_bus_pair.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@tab = local_unnamed_addr global [8 x i64] [i64 3, i64 1, i64 4, i64 1, i64 5, i64 9, i64 2, i64 6], align 16

; Function Attrs: nofree noinline nosync nounwind ssp memory(read, argmem: none, inaccessiblemem: none) uwtable
define { i64, i64 } @r(i32 noundef %0) local_unnamed_addr #0 {
  %2 = icmp slt i32 %0, 1
  br i1 %2, label %3, label %5

3:                                                ; preds = %1
  %4 = sext i32 %0 to i64
  br label %15

5:                                                ; preds = %1
  %6 = add nsw i32 %0, -1
  %7 = tail call { i64, i64 } @r(i32 noundef %6)
  %8 = extractvalue { i64, i64 } %7, 0
  %9 = extractvalue { i64, i64 } %7, 1
  %10 = and i32 %0, 7
  %11 = zext nneg i32 %10 to i64
  %12 = getelementptr inbounds [8 x i64], ptr @tab, i64 0, i64 %11
  %13 = load i64, ptr %12, align 8, !tbaa !6
  %14 = add nsw i64 %8, %13
  br label %15

15:                                               ; preds = %5, %3
  %16 = phi i64 [ 0, %3 ], [ %14, %5 ]
  %17 = phi i64 [ %4, %3 ], [ %9, %5 ]
  %18 = insertvalue { i64, i64 } poison, i64 %16, 0
  %19 = insertvalue { i64, i64 } %18, i64 %17, 1
  ret { i64, i64 } %19
}

; Function Attrs: nounwind ssp uwtable
define i32 @f(i32 noundef %0) local_unnamed_addr #1 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 1.000000e+00) #3
  %3 = and i32 %2, 3
  %4 = tail call { i64, i64 } @r(i32 noundef %3)
  %5 = extractvalue { i64, i64 } %4, 0
  %6 = extractvalue { i64, i64 } %4, 1
  %7 = tail call i64 @cq_measure_sl(i64 noundef %5) #4
  %8 = trunc i64 %7 to i32
  %9 = trunc nsw i64 %6 to i32
  %10 = add nsw i32 %8, %9
  ret i32 %10
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i64 @cq_measure_sl(i64 noundef) local_unnamed_addr #2

attributes #0 = { nofree noinline nosync nounwind ssp memory(read, argmem: none, inaccessiblemem: none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!7 = !{!"long", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
