; lowering_reject_classical_mux_phi_spec_scrubbed_base_reversed_layout.ll — DECLINE
; ⚠ bd test_C_libtooling-vsfp (2026-09-26) — RE-SPELLED, and why. `@h` used to
; IGNORE its parameter 0. `dropDeadCallArguments` (SpecializeDetect.h) now replaces
; an integer/fp argument whose callee parameter has NO USES by a constant before any
; stage reads it — what `clang -O1` does to the hand-inlined twin — so that spelling
; never reaches the specializer: `t` is classical from the start and the
; classical-mux guard itself declines with this very string — the verdict AND the
; string survived while the SUBJECT (the d88e re-ask) vanished, which no stdout/stderr
; A/B can see (found by the `CQ_DEADARG_DBG` census: 33 lit modules touched).
; The added lines in `@h` (a branch-only read — see ROUND 2 below) keep the parameter live, so this file still reaches the fence it was written for. That
; residual population — a callee that READS the argument yet returns classical — is
; IR-ONLY from C at -O1 (the library TU deletes a dead read). The `env
; CQ_DEADARG_DBG=1` + `CHECK-NOT: CQ_DEADARG_DBG` pair pins that the drop does NOT
; fire here: a widening of the drop (e.g. to dataflow liveness) retires this subject
; and must re-derive it (CLAUDE.md L8).
; ⚠ ROUND 2 (bd vsfp, Rule-13 r1A/r1B): round 1's DEAD `mul` read no longer keeps the
; parameter used — the drop now asks LIVENESS (`DeadValueLiveness.h`), and a value that
; reaches no root is dead. The read is therefore a BRANCH-ONLY one now: `%vsfp.c` and an
; EMPTY diamond on it. A branch condition is a liveness ROOT (the predicate has no
; control dependence — see its LIMITS), so the parameter is LIVE in the original callee,
; the drop does not fire (the NODROP / CHECK-NOT pin below), and the clone is built as
; before; the clone's own flatten then removes the branch and the specializer records
; the slot dead. Where this module ACCEPTS, its operand is a `cq_theta` result (the
; phantom-read backstop's one exemption); where it DECLINES, the owner named here fires
; before the backstop is asked. A predicate WITH control dependence (ADCE) retires this
; subject — the pin below then turns red and the subject must be re-derived (L8).
;
; (bd test_C_libtooling-d88e, Rule-13 round r1A F-DA-1). HAND-REORDERED IR.
;
; ⚠ NO C SPELLING IS KNOWN TO PRODUCE THIS LAYOUT. The body is r1A's
; `rk04C_rev.s1.ll`: the 2-TU `k04C` module (two chained one-register lifts over a
; spec-CLASSICAL `t`, library `h(a, k) = k + 1`) after `opt -passes=instnamer`,
; with the diamond blocks moved to the order `bb14, bb12, bb9, bb7`, so the OUTER
; lift is recorded first with the INNER merge φ as its base and the inner lift then
; RAUWs that φ (see the ACCEPT sibling
; `lowering_classical_mux_phi_onereg_spec_quantum_base_reversed_layout.ll` for the
; mechanism). `opt -passes=verify` clean.
;
; `specialize()` scrubs `t`, so BOTH lifts were false. The main `def1b088` oracle
; (cq-opt `b1603d23`) ACCEPTS this at exit 0 with 0 `cqrt_measure` (the source has
; 1); the subject declines with the classical-mux guard's string, as the normal-
; layout `k04C` and its hand-inlined twin `k04T` (`int t = m + 1;`) do. Which lift
; the diagnostic is attributed to differs from the twin (the OUTER φ, recorded
; first, vs the twin's inner one) — visible only in `!dbg`, which this module has
; none of (r1A F-DA-3: twin parity is a VERDICT property).
;
; Library TU (plain C, no CQ.h):
;   int h(int a, int k) { return k + 1; }
;
; Caller TU (clang -O1 -include CQ.h), before the reorder:
;   #include <stdlib.h>
;   int h(int a, int k);
;   int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = h(q, m); int r = t; if (m > 3) r = cq_theta(t, .2); int s = r; if (m > 7) s = cq_theta(r, .4); return cq_measure(s); }
;
; Regenerate: build `k04C` (clang -O1 both TUs, llvm-link), run
; `opt -passes=instnamer`, then move blocks `bb14`, `bb12`, `bb9`, `bb7` (in that
; order) directly after the entry block by hand.
;
; RUN: env CQ_DEADARG_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK-NOT: CQ_DEADARG_DBG
; CHECK: in function main i32 (i32, ptr): cq taint escape: tainted value muxed by a classical-condition phi

; ModuleID = 'p/k04C.s1.ll'
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
define range(i32 -2147483647, -2147483648) i32 @h(i32 noundef %arg, i32 noundef %arg1) local_unnamed_addr #3 {
bb:
  %vsfp.c = icmp eq i32 %arg, 0   ; bd vsfp r2: a BRANCH-ONLY read keeps this parameter LIVE
  br i1 %vsfp.c, label %vsfp.arm, label %vsfp.join
vsfp.arm:
  br label %vsfp.join
vsfp.join:
  %i = add nsw i32 %arg1, 1
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
