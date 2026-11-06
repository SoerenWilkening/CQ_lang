; ModuleID = '/Users/sorenwilkening/Desktop/Projects/CQ_lang2/.claude/worktrees/agent-a41713d75845e4fb4/tests/calls/probes/own_small_struct_caller.c'
source_filename = "/Users/sorenwilkening/Desktop/Projects/CQ_lang2/.claude/worktrees/agent-a41713d75845e4fb4/tests/calls/probes/own_small_struct_caller.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@tab = local_unnamed_addr global [8 x i32] [i32 3, i32 1, i32 4, i32 1, i32 5, i32 9, i32 2, i32 6], align 16

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(read, argmem: none, inaccessiblemem: none) uwtable
define i64 @q(i32 noundef %0) local_unnamed_addr #0 {
  %2 = and i32 %0, 7
  %3 = zext nneg i32 %2 to i64
  %4 = getelementptr inbounds [8 x i32], ptr @tab, i64 0, i64 %3
  %5 = load i32, ptr %4, align 4, !tbaa !6
  %6 = zext i32 %0 to i64
  %7 = shl nuw i64 %6, 32
  %8 = zext i32 %5 to i64
  %9 = or disjoint i64 %7, %8
  ret i64 %9
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(read, inaccessiblemem: none) uwtable
define i32 @g(i32 noundef %0) local_unnamed_addr #1 {
  %2 = tail call i64 @q(i32 noundef 3)
  %3 = trunc i64 %2 to i32
  %4 = lshr i64 %2, 32
  %5 = trunc nuw i64 %4 to i32
  %6 = add i32 %3, %0
  %7 = add i32 %6, %5
  ret i32 %7
}

; Function Attrs: nounwind ssp uwtable
define i32 @f(i32 noundef %0) local_unnamed_addr #2 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 1.000000e+00) #4
  %3 = tail call i32 @g(i32 noundef %2)
  %4 = tail call i32 @cq_measure_si32(i32 noundef %3) #5
  ret i32 %4
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #3

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #3

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(read, argmem: none, inaccessiblemem: none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(read, inaccessiblemem: none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nomerge nounwind }
attributes #5 = { nounwind }

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
