; spec_reject_predicted_classical_round2_mask_growth_ry.ll — DECLINE (bd test_C_libtooling-cepm (round 1b)).
; bd cepm ROUND 1b — a ROUND-2 MASK-GROWTH site. `t = h(q, y)` with `y` a 6.5 classical-call-arm
; merge `%out` (`if (q > 5) y = ext_f(7);`), tainted only in ROUND 2. At round 1 the mask is `01`
; and `predictReturnTainted(h, 01)` is FALSE (`k + 1` reads only `y`); at round 2 it is `11`
; and the return is QUANTUM. Round 1 of bd cepm left `t` classical at round 1 and tainted it in
; ROUND 2, which ACCEPTED this module with a stream that is NOT the hand-inlined twin's (the
; clone's copy-out rail `copy(y + 1)` stays allocated where the twin's `-O1` folded `y + 1 > 3`
; to `y > 2`; TRACK_CEPM_3ZR4.md §5.2.1). Orchestrator ruling 2026-09-28: such a site must behave
; as on the oracle. The SETTLE step (`settleSpecPredictions`) asks `LaterTaintOracle`: `y` is a φ
; decided by the TAINTED `q > 5`, so a later round can taint it, the POSSIBLE mask is `11`, the
; prediction is quantum, and `t` is tainted AT ROUND 1 — the oracle's taint set, hence the
; oracle's verdict and string. RETIREMENT TRIGGER (L8): an owner ruling that a compiler-kept
; clone copy-out is acceptable (bd filed with this change) would make this an accept; re-derive,
; do not delete.
; Here, besides r2b's region, a trailing Ry on `y` (round 1 of bd cepm accepted it and BOTH
; sides warned `live derived record`).
;
; 6 TUs, each `clang -O1`, llvm-linked as tests/e2e/run_slice_multi.sh does.
; Caller TU (-include CQ.h):
;   int h(int a, int k);
;   int ext_f(int a);
;   int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int q = cq_theta(m, .5); int y = 0; if (q > 5) y = ext_f(7); int t = h(q, y); int q2 = cq_theta(n, .4); if (t > 3) q2 = cq_theta(q2, .2); y = cq_theta(y, .3); return cq_measure(q2) + cq_measure(q) + cq_measure(y); }
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
;
; Oracle 9a230646: the same DECLINE (byte-identical first error line). Round 1 of bd cepm: ACCEPT.
; Hand-inlined twin (r2dT.c) ACCEPTS (warned) with a different stream.
; Regenerate: docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-28-parallel/cepm_probes/mkprobes.py + gen.sh r2dC, then mkfix.py.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: cq controlled lowering: control flow under quantum control

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
  %10 = icmp sgt i32 %9, 5
  br i1 %10, label %11, label %13

11:                                               ; preds = %2
  %12 = tail call i32 @ext_f(i32 noundef 7) #4
  br label %13

13:                                               ; preds = %11, %2
  %14 = phi i32 [ %12, %11 ], [ 0, %2 ]
  %15 = tail call i32 @h(i32 noundef %9, i32 noundef %14) #4
  %16 = tail call i32 @cq_theta_si32(i32 noundef %8, double noundef 4.000000e-01) #4
  %17 = icmp sgt i32 %15, 3
  br i1 %17, label %18, label %20

18:                                               ; preds = %13
  %19 = tail call i32 @cq_theta_si32(i32 noundef %16, double noundef 2.000000e-01) #4
  br label %20

20:                                               ; preds = %18, %13
  %21 = phi i32 [ %19, %18 ], [ %16, %13 ]
  %22 = tail call i32 @cq_theta_si32(i32 noundef %14, double noundef 3.000000e-01) #4
  %23 = tail call i32 @cq_measure_si32(i32 noundef %21) #4
  %24 = tail call i32 @cq_measure_si32(i32 noundef %9) #4
  %25 = add nsw i32 %24, %23
  %26 = tail call i32 @cq_measure_si32(i32 noundef %22) #4
  %27 = add nsw i32 %25, %26
  ret i32 %27
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

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nofree nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind }

!llvm.ident = !{!0, !0, !0, !0, !0, !0}
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
