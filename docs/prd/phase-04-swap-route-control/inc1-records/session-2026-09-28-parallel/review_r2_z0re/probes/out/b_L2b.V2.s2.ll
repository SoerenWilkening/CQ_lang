; ModuleID = '/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a284a60d747f2ed82/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-28-parallel/review_r2_z0re/probes/out/b_L2b.s1.ll'
source_filename = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a284a60d747f2ed82/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-28-parallel/review_r2_z0re/probes/src/b_L2b.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: noinline nounwind ssp uwtable
define i32 @slice(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #0 {
  br label %4

3:                                                ; preds = %4
  ret i32 %11

4:                                                ; preds = %4, %2
  %5 = phi i64 [ 0, %2 ], [ %12, %4 ]
  %6 = phi i32 [ 0, %2 ], [ %11, %4 ]
  %7 = trunc i64 %5 to i32
  %8 = add i32 %7, %0
  %h = call i32 @cqrt_alloc_i32(i32 %8)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %9 = getelementptr inbounds i32, ptr %1, i64 %5
  %10 = load i32, ptr %9, align 4, !tbaa !6
  %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 3)
  %h1 = call i32 @cqrt_alloc_i32(i32 %10)
  call void @cqrt_ry_i32_controlled(i32 %h_cmp, i32 %h1, double 2.000000e-01)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp, i32 %h, i32 3)
  call void @cqrt_free(i32 %h_cmp)
  %m = call i32 @cqrt_measure_i32(i32 %h1)
  %11 = add nsw i32 %m, %6
  %12 = add nuw nsw i64 %5, 1
  %13 = icmp eq i64 %12, 3
  br i1 %13, label %3, label %4, !llvm.loop !10
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #2 {
  %3 = alloca [3 x i32], align 4
  call void @llvm.lifetime.start.p0(i64 12, ptr nonnull %3) #4
  %4 = getelementptr inbounds i8, ptr %1, i64 8
  %5 = load ptr, ptr %4, align 8, !tbaa !13
  %6 = tail call i32 @atoi(ptr nocapture noundef %5)
  store i32 %6, ptr %3, align 4, !tbaa !6
  %7 = getelementptr inbounds i8, ptr %3, i64 4
  %8 = getelementptr inbounds i8, ptr %1, i64 16
  %9 = load ptr, ptr %8, align 8, !tbaa !13
  %10 = tail call i32 @atoi(ptr nocapture noundef %9)
  store i32 %10, ptr %7, align 4, !tbaa !6
  %11 = getelementptr inbounds i8, ptr %3, i64 8
  %12 = getelementptr inbounds i8, ptr %1, i64 24
  %13 = load ptr, ptr %12, align 8, !tbaa !13
  %14 = tail call i32 @atoi(ptr nocapture noundef %13)
  store i32 %14, ptr %11, align 4, !tbaa !6
  %15 = add nsw i32 %0, 3
  %16 = call i32 @slice(i32 noundef %15, ptr noundef nonnull %3)
  call void @llvm.lifetime.end.p0(i64 12, ptr nonnull %3) #4
  ret i32 %16
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #3

declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)

declare void @cqrt_x(i32)

declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_ry_i32_controlled(i32, i32, double)

declare i32 @cqrt_measure_i32(i32)

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!13 = !{!14, !14, i64 0}
!14 = !{!"any pointer", !8, i64 0}
