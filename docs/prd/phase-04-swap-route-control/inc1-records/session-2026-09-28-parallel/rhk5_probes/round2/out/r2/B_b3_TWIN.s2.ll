; ModuleID = '/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a7712272d6ca568e9/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-28-parallel/rhk5_probes/round2/r1B/src/b3_T.s1.ll'
source_filename = "b3_T.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: noinline nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 {
  %2 = and i32 %0, 7
  %h = call i32 @cqrt_alloc_i32(i32 %2)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %h_op = call i32 @cq_template_mul_i32_hl(i32 %h, i32 3)
  %h_op1 = call i32 @cq_template_xor_i32(i32 %h, i32 %h_op)
  %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op1, i32 10)
  call void @cqrt_rz_i1(i32 %h_cmp, double 3.141590e+00), !cq.branchphase !6
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h_op1, i32 10)
  call void @cqrt_free(i32 %h_cmp)
  %h_op2 = call i32 @cq_template_add_i32_hl(i32 %h_op, i32 5)
  %h_op3 = call i32 @cq_template_add_i32_hl(i32 %h_op, i32 1)
  call void @cq_template_xor_i32_unc(i32 %h_op1, i32 %h, i32 %h_op)
  call void @cqrt_free(i32 %h_op1)
  call void @cq_template_mul_i32_hl_unc(i32 %h_op, i32 %h, i32 3)
  call void @cqrt_free(i32 %h_op)
  %m = call i32 @cqrt_measure_i32(i32 %h_op3)
  %m4 = call i32 @cqrt_measure_i32(i32 %h_op2)
  %3 = add nsw i32 %m4, %m
  call void @cqrt_ry_i32(i32 %h, double 0x3FE6666666666666)
  %m5 = call i32 @cqrt_measure_i32(i32 %h)
  %4 = add nsw i32 %3, %m5
  ret i32 %4
}

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 2) i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #1 {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8, !tbaa !7
  %5 = tail call i32 @atoi(ptr nocapture noundef %4)
  %6 = tail call i32 @slice(i32 noundef %5)
  %7 = and i32 %6, 1
  ret i32 %7
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #2

declare void @cqrt_rz_i1(i32, double)

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

declare void @cqrt_x(i32)

declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare i32 @cq_template_mul_i32_hl(i32, i32)

declare i32 @cq_template_xor_i32(i32, i32)

declare i32 @cq_template_add_i32_hl(i32, i32)

declare i32 @cqrt_measure_i32(i32)

declare void @cq_template_xor_i32_unc(i32, i32, i32)

declare void @cq_template_mul_i32_hl_unc(i32, i32, i32)

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{}
!7 = !{!8, !8, i64 0}
!8 = !{!"any pointer", !9, i64 0}
!9 = !{!"omnipotent char", !10, i64 0}
!10 = !{!"Simple C/C++ TBAA"}
