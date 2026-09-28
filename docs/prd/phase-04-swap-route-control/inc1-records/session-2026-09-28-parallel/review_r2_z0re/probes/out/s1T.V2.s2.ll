; ModuleID = '/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a284a60d747f2ed82/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-28-parallel/review_r2_z0re/probes/out/s1T.s1.ll'
source_filename = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a284a60d747f2ed82/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-28-parallel/review_r2_z0re/probes/src/s1T.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [2 x i8] c"x\00", align 1

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #0 {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8, !tbaa !6
  %5 = tail call i32 @atoi(ptr nocapture noundef %4)
  %6 = getelementptr inbounds i8, ptr %1, i64 16
  %7 = load ptr, ptr %6, align 8, !tbaa !6
  %8 = tail call i32 @atoi(ptr nocapture noundef %7)
  %h = call i32 @cqrt_alloc_i32(i32 %5)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %h3 = call i32 @cqrt_alloc_i32(i32 %8)
  call void @cqrt_ry_i32(i32 %h3, double 2.500000e-01)
  %9 = icmp sgt i32 %0, 1000
  br i1 %9, label %10, label %12

10:                                               ; preds = %2
  %11 = tail call i32 @puts(ptr noundef nonnull dereferenceable(1) @.str)
  br label %12

12:                                               ; preds = %10, %2
  %13 = add nsw i32 %8, 100
  %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 3)
  %out = call i32 @cqrt_alloc_i32(i32 0)
  %selop = call i32 @cqrt_alloc_i32(i32 %13)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %selop, i32 %out)
  call void @cqrt_x(i32 %h_cmp)
  %selop1 = call i32 @cqrt_alloc_i32(i32 5)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %selop1, i32 %out)
  call void @cqrt_x(i32 %h_cmp)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp, i32 %h, i32 3)
  call void @cqrt_free(i32 %h_cmp)
  call void @cqrt_ry_i32(i32 %out, double 2.500000e-01)
  %h_cmp2 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h3, i32 7)
  call void @cqrt_ry_i32_controlled(i32 %h_cmp2, i32 %out, double 5.000000e-01)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp2, i32 %h3, i32 7)
  call void @cqrt_free(i32 %h_cmp2)
  %m = call i32 @cqrt_measure_i32(i32 %out)
  %m4 = call i32 @cqrt_measure_i32(i32 %h)
  %14 = add nsw i32 %m4, %m
  ret i32 %14
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #1

; Function Attrs: nofree nounwind
declare noundef i32 @puts(ptr nocapture noundef readonly) local_unnamed_addr #2

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_copy_i32_controlled(i32, i32, i32)

declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)

declare void @cqrt_x(i32)

declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cqrt_ry_i32(i32, double)

declare void @cqrt_ry_i32_controlled(i32, i32, double)

declare i32 @cqrt_measure_i32(i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nofree nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nofree nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

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
