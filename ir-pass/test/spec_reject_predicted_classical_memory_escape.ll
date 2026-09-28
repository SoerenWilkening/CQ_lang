; spec_reject_predicted_classical_memory_escape.ll — DECLINE (bd test_C_libtooling-cepm (negative)).
; `int G; h(a,k) { G = a; return k + 1; }` returns a classical value but lets the quantum
; argument ESCAPE THROUGH MEMORY. The predictor says classical (the store is not a use it
; follows), so the result is untainted — and the callee is still refused by `scanBody` (a store
; is not reversibilizable), loudly, at detection: an untainted result never makes a callee
; liftable.
;
; 2 TUs, each `clang -O1`, llvm-linked as tests/e2e/run_slice_multi.sh does.
; Caller TU (-include CQ.h):
;   int h(int a, int k);
;   extern int G;
;   int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int q = cq_theta(m, .5); int t = h(q, m); int r = m; if (t > 3) r = m + 5; return cq_measure(r) + cq_measure(q) + cq_measure(G); }
; Library TU 1 (plain C):
;   int G;
;   int h(int a, int k) { G = a; return k + 1; }
;
; Oracle 9a230646: the same DECLINE (byte-identical first error line).
; Hand-inlined twin (nmT.c) declines `tainted value stored to memory` (a different owner, same verdict).
; Regenerate: docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-28-parallel/cepm_probes/mkprobes.py + gen.sh nmC, then mkfix.py.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: cq specialization: callee contains a non-reversibilizable construct under quantum lift (memory access)

; ModuleID = 'llvm-link'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@G = local_unnamed_addr global i32 0, align 4

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #0 {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8, !tbaa !6
  %5 = tail call i32 @atoi(ptr nocapture noundef %4)
  %6 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 5.000000e-01) #4
  %7 = tail call i32 @h(i32 noundef %6, i32 noundef %5) #4
  %8 = icmp sgt i32 %7, 3
  %9 = add nsw i32 %5, 5
  %10 = select i1 %8, i32 %9, i32 %5
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #4
  %12 = tail call i32 @cq_measure_si32(i32 noundef %6) #4
  %13 = add nsw i32 %12, %11
  %14 = load i32, ptr @G, align 4, !tbaa !10
  %15 = tail call i32 @cq_measure_si32(i32 noundef %14) #4
  %16 = add nsw i32 %13, %15
  ret i32 %16
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(write, argmem: none, inaccessiblemem: none) uwtable
define range(i32 -2147483647, -2147483648) i32 @h(i32 noundef %0, i32 noundef %1) local_unnamed_addr #3 {
  store i32 %0, ptr @G, align 4, !tbaa !10
  %3 = add nsw i32 %1, 1
  ret i32 %3
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nofree nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(write, argmem: none, inaccessiblemem: none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!10 = !{!11, !11, i64 0}
!11 = !{!"int", !8, i64 0}
