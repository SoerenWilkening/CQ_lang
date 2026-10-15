; iosink_accept_mux_measure_kept.ll — ACCEPT (Rule-13 round 5 F-R5-1, the
; MAIN-BRANCH P1). `return cq_measure(v * m)` where `v` is the IO-sink mux rail.
; On aad63450 (and every binary before this fix) `v*m` was CLASSICAL: the mul
; ran on the HANDLE NUMBER and the bd 21mg never-quantum path DELETED the user's
; measurement. With the rail re-seeded, the product is the Q*C template
; `cq_template_mul_i32_hl(%out, m)` and the measurement is kept.
;
; Source (clang -O1 -include CQ.h):
;   #include <stdio.h>
;   #include <stdlib.h>
;   int main(int argc, char **argv) { int m = atoi(argv[1]); int q = m; cq_theta(&q, .5); int v = 3; if (q > 5) { printf("%d", q); v = 7; } return cq_measure(v * m); }
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.ll
; CHECK: %[[OUT:[a-z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK: call void @cqrt_xorc_i32_controlled(i32 %{{[a-z0-9_.]+}}, i32 %[[OUT]], i32 7)
; CHECK: %[[P:[a-z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[OUT]], i32 %{{[a-z0-9_.]+}})
; CHECK: call i32 @cqrt_measure_i32(i32 %[[P]])
; NEG-NOT: mul nsw i32 %out

; ModuleID = '/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a2b9793f123da59f8/te_scratch/r5/k06_io_inmain_meas.c'
source_filename = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a2b9793f123da59f8/te_scratch/r5/k06_io_inmain_meas.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [3 x i8] c"%d\00", align 1

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #0 {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8, !tbaa !6
  %5 = tail call i32 @atoi(ptr nocapture noundef %4)
  %6 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 5.000000e-01) #4
  %7 = icmp sgt i32 %6, 5
  br i1 %7, label %8, label %10

8:                                                ; preds = %2
  %9 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %6)
  br label %10

10:                                               ; preds = %8, %2
  %11 = phi i32 [ 7, %8 ], [ 3, %2 ]
  %12 = mul nsw i32 %11, %5
  %13 = tail call i32 @cq_measure_si32(i32 noundef %12) #4
  ret i32 %13
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: nofree nounwind
declare noundef i32 @printf(ptr nocapture noundef readonly, ...) local_unnamed_addr #3

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
