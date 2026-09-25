; lowering_classical_mux_phi_onereg_spec_quantum_base_reversed_layout.ll — ACCEPT
; (bd test_C_libtooling-d88e, Rule-13 round r1A F-DA-1: the record's
; WeakTrackingVH pin for the LIFT-ORDER case). HAND-REORDERED IR.
;
; ⚠ NO C SPELLING IS KNOWN TO PRODUCE THIS LAYOUT. The body is r1A's
; `rk04Q_rev.s1.ll`: the 2-TU `k04Q` module (two chained one-register lifts over a
; spec-QUANTUM `t`) after `opt -passes=instnamer`, with the four blocks of the two
; diamonds moved to the order `bb14, bb12, bb9, bb7` — the OUTER diamond's merge
; `bb14` laid out BEFORE the inner merge `bb9`. `clang -O1` lays them out the other
; way; the pass's own block-creating stages (unroller, PredMux, RegionFlatten) were
; NOT enumerated as producers. `opt -passes=verify` clean.
;
; WHY IT MATTERS. `declineClassicalMuxes` walks blocks in LAYOUT order and
; `resolveWireBase` stops at a φ, so the OUTER lift of
; `%i15 = phi(%i13 = cq_theta(%i10, .4), %i10)` is RECORDED FIRST with the INNER
; merge φ `%i10 = phi(%i8 = cq_theta(%i5, .2), %i5)` as its BASE; the inner lift
; then RAUWs `%i10` onto `%i5` and ERASES it. Only a TRACKING handle carries the
; outer record onto `%i5`; a `WeakVH` would null it and the re-ask
; (`declineFalsifiedMergePhiLifts`) would decline this CORRECT module (r1A measured
; exactly that with an env-switched `WeakVH` read: exit 1). This fixture is the pin
; the corpus lacked — the one other tracking case, `retargetSite`'s fp rebuild, is
; `..._spec_quantum_base_fp_rebuilt.ll`.
;
; The stream is `k04Q`'s (traces byte-identical under three argv, r1A): both Rys
; fire IN PLACE on the clone's returned handle, one measurement of that handle, no
; φ left. Like `lowering_classical_mux_phi_onereg_spec_quantum_base.ll` it is a
; lyyf-(B) DEPHASED stream (the clone's copy-out keeps `q` live; `opt` warns
; `non-diagonal gate over a live derived record` twice) — a regression pin, not a
; correctness witness. Its spec-CLASSICAL sibling declines:
; `lowering_reject_classical_mux_phi_spec_scrubbed_base_reversed_layout.ll`.
;
; Library TU (plain C, no CQ.h):
;   int h(int a, int k) { return a + k; }
;
; Caller TU (clang -O1 -include CQ.h), before the reorder:
;   #include <stdlib.h>
;   int h(int a, int k);
;   int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = h(q, m); int r = t; if (m > 3) r = cq_theta(t, .2); int s = r; if (m > 7) s = cq_theta(r, .4); return cq_measure(s); }
;
; Regenerate: build `k04Q` (clang -O1 both TUs, llvm-link), run
; `opt -passes=instnamer`, then move blocks `bb14`, `bb12`, `bb9`, `bb7` (in that
; order) directly after the entry block by hand.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s \
; RUN:   | %filecheck %s
; CHECK-LABEL: define i32 @main(
; CHECK:      [[Q:%[a-z0-9.]+]] = call i32 @cqrt_alloc_i32(i32 %i3)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 [[Q]], double 5.000000e-01)
; CHECK-NEXT: [[T:%[a-z0-9.]+]] = tail call i32 @__cq_q_h_01(i32 noundef [[Q]], i32 noundef %i3)
; CHECK-NOT:  {{phi|cqrt_alloc}}
; CHECK:      bb14:
; CHECK-NEXT: [[M:%[a-z0-9.]+]] = call i32 @cqrt_measure_i32(i32 [[T]])
; CHECK-NEXT: ret i32 [[M]]
; CHECK-NOT:  {{phi|cqrt_alloc}}
; CHECK:      bb12:
; CHECK-NEXT: call void @cqrt_ry_i32(i32 [[T]], double 4.000000e-01)
; CHECK-NOT:  {{phi|cqrt_alloc}}
; CHECK:      bb7:
; CHECK-NEXT: call void @cqrt_ry_i32(i32 [[T]], double 2.000000e-01)
; CHECK-NOT:  {{phi|cqrt_alloc}}
; CHECK:      {{^}$}}

; ModuleID = 'p/k04Q.s1.ll'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %arg, ptr nocapture noundef readonly %arg1) local_unnamed_addr #0 {
bb:
  %i = getelementptr inbounds i8, ptr %arg1, i64 8
  %i2 = load ptr, ptr %i, align 8, !tbaa !6
  %i3 = tail call i32 @atoi(ptr nocapture noundef %i2)
  %i4 = tail call i32 @cq_theta_si32(i32 noundef %i3, double noundef 5.000000e-01) #4
  %i5 = tail call i32 @h(i32 noundef %i4, i32 noundef %i3) #4
  %i6 = icmp sgt i32 %i3, 3
  br i1 %i6, label %bb7, label %bb9

bb14:                                             ; preds = %bb12, %bb9
  %i15 = phi i32 [ %i13, %bb12 ], [ %i10, %bb9 ]
  %i16 = tail call i32 @cq_measure_si32(i32 noundef %i15) #4
  ret i32 %i16
bb12:                                             ; preds = %bb9
  %i13 = tail call i32 @cq_theta_si32(i32 noundef %i10, double noundef 4.000000e-01) #4
  br label %bb14

bb9:                                              ; preds = %bb7, %bb
  %i10 = phi i32 [ %i8, %bb7 ], [ %i5, %bb ]
  %i11 = icmp sgt i32 %i3, 7
  br i1 %i11, label %bb12, label %bb14

bb7:                                              ; preds = %bb
  %i8 = tail call i32 @cq_theta_si32(i32 noundef %i5, double noundef 2.000000e-01) #4
  br label %bb9

}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @h(i32 noundef %arg, i32 noundef %arg1) local_unnamed_addr #3 {
bb:
  %i = add nsw i32 %arg1, %arg
  ret i32 %i
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nofree nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
