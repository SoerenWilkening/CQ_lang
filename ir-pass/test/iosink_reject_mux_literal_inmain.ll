; iosink_reject_mux_literal_inmain.ll — DECLINE (bd test_C_libtooling-xdu2.13 / 3jru round 5).
;
; Rule-13 round 5 F-R5-1 (P1). `v = 3; if (q > 5) { printf(...); v = 7; }` is
; lowered by `lowerControlledIOSinks` (7c'), which REPLACES the constant-incoming
; merge φ with a fresh rail `%out`. That rail was inserted into `Tainted` directly
; and never re-seeded, so `v*m` stayed CLASSICAL and the literal `v*m == n` was the
; HANDLE NUMBER times m (exit 0 on 7862ee3a). The rail is now registered in
; `taint.UntaintedMergeRails`, so `repropagateControlMerges` (which runs after the
; IO-sink stage in both entry points) re-seeds it through `propagateWorklist`; the
; literal is quantum at final taint and the post-fixpoint literal re-ask fires.
;
; Source (clang -O1 -include CQ.h):
;   #include <stdio.h>
;   #include <stdlib.h>
;   int main(int argc, char **argv) { int m = atoi(argv[1]), n = atoi(argv[2]);
;     int q2 = cq_theta(0, .5); int q = cq_theta(m, .5); int v = 3;
;     if (q > 5) { printf("%d", q); v = 7; }
;     int a = 7; if ((q2 > 1) & (v * m == n)) a += 3;
;     return cq_measure(a) + cq_measure(q2); }
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: cq controlled lowering: classical condition literal became quantum-derived under quantum control

; ModuleID = '/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a2b9793f123da59f8/te_scratch/r5/k11_io_lit_inmain.c'
source_filename = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a2b9793f123da59f8/te_scratch/r5/k11_io_lit_inmain.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [3 x i8] c"%d\00", align 1

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #0 {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8, !tbaa !6
  %5 = tail call i32 @atoi(ptr nocapture noundef %4)
  %6 = getelementptr inbounds i8, ptr %1, i64 16
  %7 = load ptr, ptr %6, align 8, !tbaa !6
  %8 = tail call i32 @atoi(ptr nocapture noundef %7)
  %9 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #4
  %10 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 5.000000e-01) #4
  %11 = icmp sgt i32 %10, 5
  br i1 %11, label %12, label %14

12:                                               ; preds = %2
  %13 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %10)
  br label %14

14:                                               ; preds = %12, %2
  %15 = phi i32 [ 7, %12 ], [ 3, %2 ]
  %16 = icmp sgt i32 %9, 1
  %17 = mul nsw i32 %15, %5
  %18 = icmp eq i32 %17, %8
  %19 = and i1 %16, %18
  %20 = select i1 %19, i32 10, i32 7
  %21 = tail call i32 @cq_measure_si32(i32 noundef %20) #4
  %22 = tail call i32 @cq_measure_si32(i32 noundef %9) #4
  %23 = add nsw i32 %22, %21
  ret i32 %23
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
