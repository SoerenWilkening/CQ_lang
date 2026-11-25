; ModuleID = '/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a2408001a46e626f3/tests/uncompute/probes/rule6_arm_exit.c'
source_filename = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a2408001a46e626f3/tests/uncompute/probes/rule6_arm_exit.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@cell = local_unnamed_addr global i64 0, align 8
@side = local_unnamed_addr global i64 0, align 8

; Function Attrs: nounwind ssp uwtable
define noundef i64 @ae(i64 noundef %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i64 @cq_theta_sl(i64 noundef %0, double noundef 1.000000e+00) #3
  store i64 %4, ptr @cell, align 8, !tbaa !6
  %5 = icmp eq i32 %1, 0
  br i1 %5, label %6, label %13

6:                                                ; preds = %3
  %7 = tail call fastcc i64 @g()
  %8 = xor i64 %7, 5
  %9 = icmp eq i32 %2, 0
  br i1 %9, label %11, label %10

10:                                               ; preds = %6
  store i64 1, ptr @side, align 8, !tbaa !6
  br label %11

11:                                               ; preds = %10, %6
  %12 = add nuw nsw i64 %8, 7
  store i64 %12, ptr @cell, align 8, !tbaa !6
  br label %13

13:                                               ; preds = %3, %11
  ret i64 0
}

declare i64 @cq_theta_sl(i64 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(read, argmem: none, inaccessiblemem: none) uwtable
define internal fastcc range(i64 0, 2) i64 @g() unnamed_addr #2 {
  %1 = load i64, ptr @cell, align 8, !tbaa !6
  %2 = icmp sgt i64 %1, 0
  %3 = zext i1 %2 to i64
  ret i64 %3
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(read, argmem: none, inaccessiblemem: none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nomerge nounwind }

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
