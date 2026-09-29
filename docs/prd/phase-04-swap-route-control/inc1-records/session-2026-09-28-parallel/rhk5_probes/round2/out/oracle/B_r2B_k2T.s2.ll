; ModuleID = '/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a7712272d6ca568e9/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-28-parallel/rhk5_probes/round2/r1B/src/r2B_k2T.s1.ll'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@K = internal global i32 7, align 4

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #0 {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8, !tbaa !6
  %5 = tail call i32 @atoi(ptr nocapture noundef %4)
  %6 = and i32 %5, 7
  %h = call i32 @cqrt_alloc_i32(i32 %6)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %h_op = call i32 @cq_template_mul_i32_hl(i32 %h, i32 3)
  %7 = add nsw i32 %5, 1
  %8 = tail call i32 @__cq_q_g_1(i32 noundef %h_op) #4
  call void @cqrt_ry_i32(i32 %h, double 0x3FE6666666666666)
  %m = call i32 @cqrt_measure_i32(i32 %8)
  %9 = add nsw i32 %7, %m
  %m1 = call i32 @cqrt_measure_i32(i32 %h)
  %10 = add nsw i32 %9, %m1
  ret i32 %10
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483647, -2147483648) i32 @g(i32 noundef %0) local_unnamed_addr #2 {
  %2 = mul nsw i32 %0, 5
  %3 = add nsw i32 %2, 1
  ret i32 %3
}

declare void @cqrt_copy_i32(i32, i32)

; Function Attrs: mustprogress norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal i32 @__cq_q_g_1(i32 noundef %0) local_unnamed_addr #3 {
  %h_op = call i32 @cq_template_mul_i32_hl(i32 %0, i32 5)
  %h_op1 = call i32 @cq_template_add_i32_hl(i32 %h_op, i32 1)
  %cqq.out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %h_op1, i32 %cqq.out)
  call void @cq_template_add_i32_hl_unc(i32 %h_op1, i32 %h_op, i32 1)
  call void @cq_template_mul_i32_hl_unc(i32 %h_op, i32 %0, i32 5)
  call void @cqrt_free(i32 %h_op)
  call void @cqrt_free(i32 %h_op1)
  ret i32 %cqq.out
}

declare i32 @cq_template_mul_i32_hl(i32, i32)

declare i32 @cq_template_add_i32_hl(i32, i32)

declare i32 @cqrt_alloc_i32(i32)

declare void @cq_template_add_i32_hl_unc(i32, i32, i32)

declare void @cq_template_mul_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_measure_i32(i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nofree nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress norecurse nosync nounwind ssp memory(readwrite) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind }

!llvm.ident = !{!0, !0}
!llvm.module.flags = !{!1, !2, !3, !4, !5}

!0 = !{!"Homebrew clang version 19.1.7"}
!1 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}
!6 = !{!7, !7, i64 0}
!7 = !{!"any pointer", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
