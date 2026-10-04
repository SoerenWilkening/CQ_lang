; lowering_reject_classical_mux_phi_spec_scrubbed_base_fp.ll — DECLINE (bd test_C_libtooling-d88e, P1 silent miscompile, found by
; ⚠ bd test_C_libtooling-vsfp (2026-09-26) — RE-SPELLED, and why. `@hf` used to
; IGNORE its parameter 0. `dropDeadCallArguments` (SpecializeDetect.h) now replaces
; an integer/fp argument whose callee parameter has NO USES by a constant before any
; stage reads it — what `clang -O1` does to the hand-inlined twin — so that spelling
; never reaches the specializer: `t` is classical from the start and the
; classical-mux guard itself declines with this very string — the verdict AND the
; string survived while the SUBJECT (the d88e re-ask) vanished, which no stdout/stderr
; A/B can see (found by the `CQ_DEADARG_DBG` census: 33 lit modules touched).
; The added lines in `@hf` (a branch-only read — see ROUND 2 below) keep the parameter live, so this file still reaches the fence it was written for. That
; residual population — a callee that READS the argument yet returns classical — is
; IR-ONLY from C at -O1 (the library TU deletes a dead read). The `env
; CQ_DEADARG_DBG=1` + `CHECK-NOT: CQ_DEADARG_DBG` pair pins that the drop does NOT
; fire here: a widening of the drop (e.g. to dataflow liveness) retires this subject
; and must re-derive it (CLAUDE.md L8).
; ⚠ bd test_C_libtooling-cepm (2026-09-28) — the "IR-ONLY from C at -O1" claim just above
; is FALSE: a read that reaches a call the pass cannot prove pure (a callee in another TU
; whose own callee is in yet another TU: `h(a,k) { g(a); return k + 1; }`) keeps the
; parameter live from C. Since bd cepm such a call's RESULT is left classical at
; propagation (`predictReturnTainted` false) and never reaches this fence. ⚠ AND THIS
; FILE'S "added lines in `@hf`" SENTENCE ABOVE IS STALE (found 2026-09-28, pre-existing):
; `@hf` below carries NO branch-only read, and the CHECK lines pin that the drop DOES
; fire (`drop arg 0 of @hf`), so this module declines at the classical-mux guard with
; `t` classical from the start — the d88e re-ask is NOT its owner.
; ⚠⚠ ROUND 2 (bd vsfp, Rule-13 r1A/r1B) — THIS FILE'S d88e SUBJECT IS NOT CONSTRUCTIBLE
; ANY MORE, AND IT NOW PINS THE TWIN'S VERDICT. Round 1 kept `@hf`'s first parameter
; "used" with a dead `fmul`; round 2's drop asks LIVENESS, so that read is dead. The
; branch-only read the other re-spelled d88e fixtures use makes an FP-returning clone
; carry a tainted terminator, which `predictReturnTainted` over-approximates to
; TAINTED — the module then declines at `floating-point return-taint could not be
; proven`, a different owner (measured). A classical-FP-return clone with a LIVE
; tainted parameter needs a read that reaches a root without control flow or data
; flow into the return, and a pure clone body has no such root: the cell is empty. So
; the original spelling is restored: the drop fires (pinned by the DBG line below),
; `t = hf(0.0, m)` is classical from the start, and the module declines exactly as
; its hand-inlined twin (`t = m + 1.0`) does, at the classical-mux guard with the
; very string below. The d88e re-ask's FP path keeps no lit pin of its own; its
; int path is pinned by the 13 sibling fixtures (the code is shared). Retirement
; trigger: a clone-return predictor precise under control flow makes the
; branch-only spelling reachable again — re-spell then.
;
; bd 9bhg's Rule-13 round r1A, F-9A-1): the f64 register (a `double` spec site whose clone returns the classical `k + 1.0`; `t` is a `cq_theta_f64` register at round 1).
;
; A TWO-TU module: the caller TU (`-include CQ.h`) llvm-linked with a plain-C
; library TU, exactly as tests/e2e/run_slice_multi.sh builds one. `t = h(q, m)`
; reads the tainted `q`, so `propagate` taints `t` CONSERVATIVELY and every stage
; before `specialize()` sees it as a quantum REGISTER. `declineClassicalMuxes`'
; one-register lift (`liftOneRegisterMergePhi`) therefore proved the
; classical-condition merge phi `phi(t, @cq_theta_f64(t, .2))` (f64) a pure renaming of ONE
; register, RAUW'd it to its wire base `t` and erased it. `specialize()` then
; clones `h`, proves the clone returns the CLASSICAL `k + 1`, and
; `scrubForwardCone` untaints `t`: the lift's premise is false after the fact.
; Before this fence the rotation lowered as a SOURCE on a fresh rail that nothing
; reads and the user's `cq_measure` read the classical `t` down the bd 21mg
; classical-measure path — NO measurement, `opt` exit 0, stage-2b STRICT clean
; (measured on main `def1b088`, cq-opt `b1603d23`: 0 `cqrt_measure` in the lowered
; module, 1 in the source). bd `test_C_libtooling-l3oi`'s fence could not see it:
; no EMITTED gate reads `t` — the consumers were reached through a RAUW.
;
; THE CORRECT DISPOSITION IS THE HAND-INLINED TWIN'S (`int t = m + 1;`, the same
; caller with `h`'s classical return written directly), and the twin DECLINES at
; `declineClassicalMuxes` with exactly the string below (measured on the same
; oracle): the phi muxes the classical `t` and a quantum register under a
; classical condition, a real data mux and not a renaming. The lift now RECORDS
; its taint-dependent premise (`taint.LiftedMergePhis`) and
; `declineFalsifiedMergePhiLifts` RE-ASKS it at FINAL taint right after
; `specialize()` in both entry points (CLAUDE.md L1: record, then re-ask).
;
; (Here the library function is `hf` and its classical return is `k + 1.0`; the
; hand-inlined twin is `double t = m + 1.0;`, measured to decline with the same
; string. Its SPEC-QUANTUM sibling, whose site `specialize()` REBUILDS to an `i32`
; handle, is `lowering_classical_mux_phi_onereg_spec_quantum_base_fp_rebuilt.ll`.)
;
; Library TU (plain C, no CQ.h):
;   double hf(double a, double k) { return k + 1.0; }
;
; Caller TU (clang -O1 -include CQ.h):
;   #include <stdlib.h>
;   double hf(double a, double k);
;   int main(int c, char **v) { double m = atof(v[1]); double q = m; cq_theta(&q, .5); double t = hf(q, m); double r = t; if (m > 3) { r = t; cq_theta(&r, .2); } return (int) cq_measure(r); }
;
; Regenerate: clang -O1 -emit-llvm -S the two TUs as above, then
;   llvm-link -S caller.ll lib.ll -o <this file's body>.
;
; RUN: env CQ_DEADARG_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: CQ_DEADARG_DBG: drop arg 0 of @hf in @main
; CHECK: in function main i32 (i32, ptr): cq taint escape: tainted value muxed by a classical-condition phi

; ModuleID = 'llvm-link'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #0 {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8, !tbaa !6
  %5 = tail call double @atof(ptr noundef %4)
  %6 = tail call double @cq_theta_f64(double noundef %5, double noundef 5.000000e-01) #4
  %7 = tail call double @hf(double noundef %6, double noundef %5) #4
  %8 = fcmp ogt double %5, 3.000000e+00
  br i1 %8, label %9, label %11

9:                                                ; preds = %2
  %10 = tail call double @cq_theta_f64(double noundef %7, double noundef 2.000000e-01) #4
  br label %11

11:                                               ; preds = %9, %2
  %12 = phi double [ %10, %9 ], [ %7, %2 ]
  %13 = tail call double @cq_measure_f64(double noundef %12) #4
  %14 = fptosi double %13 to i32
  ret i32 %14
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare double @atof(ptr nocapture noundef) local_unnamed_addr #1

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #2

declare double @cq_measure_f64(double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define noundef double @hf(double noundef %0, double noundef %1) local_unnamed_addr #3 {
  %3 = fadd double %1, 1.000000e+00
  ret double %3
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
