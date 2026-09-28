; ModuleID = '/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a284a60d747f2ed82/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-28-parallel/review_r2_z0re/probes/src/s6T.c'
source_filename = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a284a60d747f2ed82/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-28-parallel/review_r2_z0re/probes/src/s6T.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [2 x i8] c"x\00", align 1
@.str.1 = private unnamed_addr constant [2 x i8] c"y\00", align 1

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #0 {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8, !tbaa !6
  %5 = tail call i32 @atoi(ptr nocapture noundef %4)
  %6 = getelementptr inbounds i8, ptr %1, i64 16
  %7 = load ptr, ptr %6, align 8, !tbaa !6
  %8 = tail call i32 @atoi(ptr nocapture noundef %7)
  %9 = getelementptr inbounds i8, ptr %1, i64 24
  %10 = load ptr, ptr %9, align 8, !tbaa !6
  %11 = tail call i32 @atoi(ptr nocapture noundef %10)
  %12 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 5.000000e-01) #4
  %13 = tail call i32 @cq_theta_si32(i32 noundef %8, double noundef 2.500000e-01) #4
  %14 = icmp sgt i32 %0, 1000
  br i1 %14, label %15, label %17

15:                                               ; preds = %2
  %16 = tail call i32 @puts(ptr noundef nonnull dereferenceable(1) @.str)
  br label %17

17:                                               ; preds = %15, %2
  %18 = icmp sgt i32 %0, 2000
  br i1 %18, label %19, label %21

19:                                               ; preds = %17
  %20 = tail call i32 @puts(ptr noundef nonnull dereferenceable(1) @.str.1)
  br label %21

21:                                               ; preds = %19, %17
  %22 = icmp sgt i32 %12, 3
  %23 = icmp sgt i32 %8, -50
  %24 = select i1 %22, i1 %23, i1 false
  %25 = mul nsw i32 %11, 3
  %26 = add nsw i32 %25, 1
  %27 = select i1 %24, i32 %26, i32 %11
  %28 = icmp sgt i32 %13, 7
  %29 = select i1 %28, double 7.500000e-01, double 2.500000e-01
  %30 = tail call i32 @cq_theta_si32(i32 noundef %27, double noundef %29) #4
  %31 = tail call i32 @cq_measure_si32(i32 noundef %30) #4
  %32 = tail call i32 @cq_measure_si32(i32 noundef %12) #4
  %33 = add nsw i32 %32, %31
  ret i32 %33
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: nofree nounwind
declare noundef i32 @puts(ptr nocapture noundef readonly) local_unnamed_addr #3

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nofree nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nofree nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!7 = !{!"any pointer", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
