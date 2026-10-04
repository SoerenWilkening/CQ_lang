; spec_accept_predicted_classical_measured_callee.ll — ACCEPT (bd test_C_libtooling-cepm (round 2; bd we38)).
; THE READING CALLEE. `h` READS its quantum argument — through a call to `g`, whose own
; callee `f2` is an external in `g`'s TU, so `-O1` infers no `memory(none)`/`willreturn`
; for `g` and the pass's liveness (DeadValueLiveness.h) keeps the call as a ROOT, so bd
; vsfp's dead-argument drop does NOT fire — and returns the CLASSICAL `k + 1`.
; `predictReturnTainted(h, 01)` is FALSE (the masked parameter reaches neither the
; `ret` nor a conditional terminator), so since bd cepm propagation leaves the call's
; RESULT classical (`specCallResultPredictedClassical`, SpecializeClone.h): no stage
; before `specialize()` reads it as a register, and the clone `@__cq_q_h_01` (built
; unchanged) returns the classical value. Before bd cepm the result was tainted
; CONSERVATIVELY and scrubbed only after both control rounds.
; Here the site's SECOND argument is `F(n)`, where `F` holds a `cq_theta` but returns a MEASURED
; classical value (`F(n){ r = n; cq_theta(&r,.3); return n + cq_measure(r); }`). Round 1b's
; `LaterTaintOracle` counted any call to a callee holding a `cq_theta` as a value a later round can
; taint (a SYNTACTIC answer, L5), predicted the site quantum, tainted `t` at round 1, and bd l3oi's
; fence declined. Round 2 removed that seed (Rule-13 r1A F-r1A-1 / bd we38): the only channel by which
; a call RESULT gains taint beyond its operands is bd 3jru's return crossing, and that growth is
; refused by `declineQuantumReturnCalls` before `specialize()` (`spec_reject_predicted_classical_
; round2_return_crossing.ll` pins it). RETIREMENT TRIGGER (L8): the day that refusal is relaxed,
; a crossing onto an ARGUMENT the oracle does not foresee ends at `specialize()`'s check; a crossing
; onto the recorded SITE ITSELF is kept loud only by `scanBody`'s refusal of a callee that holds a
; `cq_*` primitive (Rule-13 r2 F-r2-5) — re-derive this pair then.
;
; 7 TUs, each `clang -O1`, llvm-linked as tests/e2e/run_slice_multi.sh does.
; Caller TU (-include CQ.h):
;   int h(int a, int k);
;   int F(int n);
;   int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int q = m; cq_theta(&q, .5); int y = F(n); int t = h(q, y); int q2 = n; cq_theta(&q2, .4); if (t > 3) cq_theta(&q2, .2); return cq_measure(q2) + cq_measure(q); }
; Library TU 1 (plain C):
;   /* h READS a (a call to g, an external here) and returns the CLASSICAL k + 1. */
;   void g(int a);
;   int h(int a, int k) { g(a); return k + 1; }
; Library TU 2 (plain C):
;   /* f2 is an external here: -O1 keeps the unused call and infers nothing. */
;   int f2(int a);
;   void g(int a) { f2(a); }
; Library TU 3 (plain C):
;   /* f3 is an external here: f2 gets no memory(none)/willreturn, so a call to f2
;      is a liveness ROOT of the pass. */
;   int f3(int a);
;   int f2(int a) { return f3(a) + 1; }
; Library TU 4 (plain C):
;   int f3(int a) { return a * 3; }
; Library TU 5 (plain C):
;   int ext_f(int a) { return a * 7 + 2; }
;   int g2(int a, int b) { return a * b + 1; }
; Library TU 6 (plain C):
;   #include "CQ.h"
;   int F(int n) { int r = n; cq_theta(&r, .3); return n + cq_measure(r); }
;
; Oracle 9a230646: DECLINE `classical call result used as a quantum register`. Round 1b: same.
; Hand-inlined twin (r6bT.c: `g(q); int t = y + 1;`) is TRACE-IDENTICAL under argv
; `5 7` and `2 9`, stage 2b STRICT clean on both (docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-28-parallel/cepm_probes/twincmp.sh).
; Regenerate: docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-28-parallel/cepm_probes/mkprobes.py + gen.sh r6bC, then mkfix.py.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s \
; RUN:   | %filecheck %s
; CHECK-LABEL: define i32 @main(
; CHECK:       %[[Y:[0-9]+]] = tail call i32 @F(
; CHECK-NEXT:  %[[T:[0-9]+]] = tail call i32 @__cq_q_h_01(i32 noundef %{{[A-Za-z0-9_.]+}}, i32 noundef %[[Y]])
; CHECK-NOT:   cq_template_icmp
; CHECK:       %[[C:[0-9]+]] = icmp sgt i32 %[[T]], 3
; CHECK-NEXT:  br i1 %[[C]],
; CHECK:       ret i32
; (Rule-13 r2: the CHECK-NOT sat between `br` and `ret`, where no icmp could appear — decorative. It
; now sits between the site and its classical compare, where a quantum compare template would be.)

; ModuleID = 'llvm-link'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #0 {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8, !tbaa !6
  %5 = tail call i32 @atoi(ptr nocapture noundef %4)
  %6 = getelementptr inbounds i8, ptr %1, i64 16
  %7 = load ptr, ptr %6, align 8, !tbaa !6
  %8 = tail call i32 @atoi(ptr nocapture noundef %7)
  %9 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 5.000000e-01) #4
  %10 = tail call i32 @F(i32 noundef %8) #4
  %11 = tail call i32 @h(i32 noundef %9, i32 noundef %10) #4
  %12 = tail call i32 @cq_theta_si32(i32 noundef %8, double noundef 4.000000e-01) #4
  %13 = icmp sgt i32 %11, 3
  br i1 %13, label %14, label %16

14:                                               ; preds = %2
  %15 = tail call i32 @cq_theta_si32(i32 noundef %12, double noundef 2.000000e-01) #4
  br label %16

16:                                               ; preds = %14, %2
  %17 = phi i32 [ %15, %14 ], [ %12, %2 ]
  %18 = tail call i32 @cq_measure_si32(i32 noundef %17) #4
  %19 = tail call i32 @cq_measure_si32(i32 noundef %9) #4
  %20 = add nsw i32 %19, %18
  ret i32 %20
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define range(i32 -2147483647, -2147483648) i32 @h(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  tail call void @g(i32 noundef %0) #4
  %3 = add nsw i32 %1, 1
  ret i32 %3
}

; Function Attrs: nounwind ssp uwtable
define void @g(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @f2(i32 noundef %0) #4
  ret void
}

; Function Attrs: nounwind ssp uwtable
define range(i32 -2147483647, -2147483648) i32 @f2(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @f3(i32 noundef %0) #4
  %3 = add nsw i32 %2, 1
  ret i32 %3
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @f3(i32 noundef %0) local_unnamed_addr #3 {
  %2 = mul nsw i32 %0, 3
  ret i32 %2
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483646, -2147483648) i32 @ext_f(i32 noundef %0) local_unnamed_addr #3 {
  %2 = mul nsw i32 %0, 7
  %3 = add nsw i32 %2, 2
  ret i32 %3
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483647, -2147483648) i32 @g2(i32 noundef %0, i32 noundef %1) local_unnamed_addr #3 {
  %3 = mul nsw i32 %1, %0
  %4 = add nsw i32 %3, 1
  ret i32 %4
}

; Function Attrs: nounwind ssp uwtable
define i32 @F(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 3.000000e-01) #4
  %3 = tail call i32 @cq_measure_si32(i32 noundef %2) #4
  %4 = add nsw i32 %3, %0
  ret i32 %4
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nofree nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind }

!llvm.ident = !{!0, !0, !0, !0, !0, !0, !0}
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
