; ModuleID = '/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a284a60d747f2ed82/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-28-parallel/review_r2_z0re/probes/src/b_c4bool.c'
source_filename = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a284a60d747f2ed82/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-28-parallel/review_r2_z0re/probes/src/b_c4bool.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 4) i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #0 {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8, !tbaa !6
  %5 = tail call i32 @atoi(ptr nocapture noundef %4)
  %6 = icmp ne i32 %5, 0
  %7 = getelementptr inbounds i8, ptr %1, i64 16
  %8 = load ptr, ptr %7, align 8, !tbaa !6
  %9 = tail call i32 @atoi(ptr nocapture noundef %8)
  %10 = icmp ne i32 %9, 0
  %11 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %10, double noundef 3.000000e-01) #3
  br i1 %11, label %12, label %14

12:                                               ; preds = %2
  %13 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %6, double noundef 2.000000e-01) #3
  br label %14

14:                                               ; preds = %12, %2
  %15 = phi i1 [ %13, %12 ], [ %6, %2 ]
  br i1 %15, label %16, label %18

16:                                               ; preds = %14
  %17 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %6, double noundef 4.000000e-01) #3
  br label %18

18:                                               ; preds = %16, %14
  %19 = phi i1 [ %17, %16 ], [ %6, %14 ]
  %20 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %19) #3
  %21 = zext i1 %20 to i32
  %22 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %15) #3
  %23 = zext i1 %22 to i32
  %24 = add nuw nsw i32 %23, %21
  %25 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %11) #3
  %26 = zext i1 %25 to i32
  %27 = add nuw nsw i32 %24, %26
  ret i32 %27
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nofree nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!7 = !{!"any pointer", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
