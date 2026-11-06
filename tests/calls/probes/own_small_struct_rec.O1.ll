; ModuleID = '/Users/sorenwilkening/Desktop/Projects/CQ_lang2/.claude/worktrees/agent-a41713d75845e4fb4/tests/calls/probes/own_small_struct_rec.c'
source_filename = "/Users/sorenwilkening/Desktop/Projects/CQ_lang2/.claude/worktrees/agent-a41713d75845e4fb4/tests/calls/probes/own_small_struct_rec.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@tab = local_unnamed_addr global [8 x i32] [i32 3, i32 1, i32 4, i32 1, i32 5, i32 9, i32 2, i32 6], align 16

; Function Attrs: nofree noinline nosync nounwind ssp memory(read, argmem: none, inaccessiblemem: none) uwtable
define i64 @r(i32 noundef %0) local_unnamed_addr #0 {
  %2 = icmp slt i32 %0, 1
  br i1 %2, label %15, label %3

3:                                                ; preds = %1
  %4 = add nsw i32 %0, -1
  %5 = tail call i64 @r(i32 noundef %4)
  %6 = trunc i64 %5 to i32
  %7 = lshr i64 %5, 32
  %8 = trunc nuw i64 %7 to i32
  %9 = and i32 %0, 7
  %10 = zext nneg i32 %9 to i64
  %11 = getelementptr inbounds [8 x i32], ptr @tab, i64 0, i64 %10
  %12 = load i32, ptr %11, align 4, !tbaa !6
  %13 = add nsw i32 %12, %6
  %14 = zext i32 %13 to i64
  br label %15

15:                                               ; preds = %1, %3
  %16 = phi i64 [ %14, %3 ], [ 0, %1 ]
  %17 = phi i32 [ %8, %3 ], [ %0, %1 ]
  %18 = zext i32 %17 to i64
  %19 = shl nuw i64 %18, 32
  %20 = or disjoint i64 %19, %16
  ret i64 %20
}

; Function Attrs: nounwind ssp uwtable
define i32 @f(i32 noundef %0) local_unnamed_addr #1 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 1.000000e+00) #3
  %3 = and i32 %2, 3
  %4 = tail call i64 @r(i32 noundef %3)
  %5 = trunc i64 %4 to i32
  %6 = lshr i64 %4, 32
  %7 = trunc nuw i64 %6 to i32
  %8 = tail call i32 @cq_measure_si32(i32 noundef %5) #4
  %9 = add nsw i32 %8, %7
  ret i32 %9
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

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
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
