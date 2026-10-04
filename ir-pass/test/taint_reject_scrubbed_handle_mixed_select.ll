; taint_reject_scrubbed_handle_mixed_select.ll — DECLINE (bd test_C_libtooling-l3oi, xdu2.13 Rule-13 round 6 F-R6-1).
; ⚠ bd test_C_libtooling-vsfp (2026-09-26) — RE-SPELLED, and why. `@h` used to
; IGNORE its parameter 0. `dropDeadCallArguments` (SpecializeDetect.h) now replaces
; an integer/fp argument whose callee parameter has NO USES by a constant before any
; stage reads it — what `clang -O1` does to the hand-inlined twin — so that spelling
; never reaches the specializer: `t` is classical from the start, no gate ever
; reads it as a handle, and that spelling now ACCEPTS with the hand-inlined twin's
; stream (bd cepm's over-decline, removed for a callee that ignores the argument) —
; pinned by `spec_accept_dropped_arg_scrubbed_handle_branch.ll`.
; The added lines in `@h` (a branch-only read — see ROUND 2 below) keep the parameter live, so this file still reaches the fence it was written for. That
; residual population — a callee that READS the argument yet returns classical — was
; called "IR-ONLY from C at -O1 (the library TU deletes a dead read)" here, and that is
; FALSE (bd test_C_libtooling-cepm, 2026-09-28): a callee whose read reaches a liveness
; ROOT the pass cannot clear — a call to a function in ANOTHER TU whose own callee is in
; yet another TU (`g(a); return k + 1;`, `-O1` infers `g` nothing) — keeps the parameter
; live from C (cepm_probes/, battery `br`…`z3`). That population no longer reaches this
; fence at all: since bd cepm propagation asks `predictReturnTainted` and leaves such a
; call's RESULT classical (`spec_accept_predicted_classical_*.ll`). THIS subject still
; reaches it because the predictor treats ANY tainted conditional terminator as a tainted
; return — even this EMPTY diamond — so `t` is still tainted conservatively; a predictor
; that asks whether the branch reaches the return retires this subject (L8: re-derive it,
; e.g. from `spec_reject_predicted_classical_inner_clone.ll`'s inner-clone shape). The `env
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
; A TWO-TU module: the caller TU (`-include CQ.h`) llvm-linked with a plain-C
; library TU, exactly as tests/e2e/run_slice_multi.sh builds one. `h(q, m)` is
; TAINTED at round 1 (it reads the tainted argument `q`), so the control
; emitters build their condition flag ON its result as a quantum HANDLE. Only
; later does `specialize()` clone `h`, prove the clone returns the CLASSICAL
; `k + 1`, and `scrubForwardCone` removes the taint. Before this fence nothing
; re-asked: the trace read `icmp_sgt_i32_hl(h4, 3)` — the INTEGER 4 used as a
; register id (exit 0, 2b clean, on aad63450 and every binary to 60ac0fcb). The
; scrub now RECORDS each value it untaints (`taint.ScrubbedByReturnTaint`) and
; `declineScrubbedHandleReads` re-asks right after `specialize()` in both entry
; points.
;
; Library TU (plain C, no CQ.h):
;   int h(int a, int k) { return k + 1; }
;
; Caller TU (clang -O1 -include CQ.h):
;   #include <stdlib.h>
;   int h(int a, int k);
;   int main(int argc, char **argv) { int m = atoi(argv[1]); int n = atoi(argv[2]); int q = m; cq_theta(&q, .5); int t = h(q, m); int r = m; if ((t > 3) & (m == n)) r = m + 5; return cq_measure(r); }
;
; Regenerate: clang -O1 -emit-llvm -S the two TUs as above, then
;   llvm-link -S caller.ll lib.ll -o <this file's body>.
;
; RUN: env CQ_DEADARG_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK-NOT: CQ_DEADARG_DBG
; CHECK: cq taint escape: classical call result used as a quantum register

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
  %10 = tail call i32 @h(i32 noundef %9, i32 noundef %5) #4
  %11 = icmp sgt i32 %10, 3
  %12 = icmp eq i32 %5, %8
  %13 = and i1 %12, %11
  %14 = add nsw i32 %5, 5
  %15 = select i1 %13, i32 %14, i32 %5
  %16 = tail call i32 @cq_measure_si32(i32 noundef %15) #4
  ret i32 %16
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483647, -2147483648) i32 @h(i32 noundef %0, i32 noundef %1) local_unnamed_addr #3 {
  %vsfp.c = icmp eq i32 %0, 0   ; bd vsfp r2: a BRANCH-ONLY read keeps this parameter LIVE
  br i1 %vsfp.c, label %vsfp.arm, label %vsfp.join
vsfp.arm:
  br label %vsfp.join
vsfp.join:
  %3 = add nsw i32 %1, 1
  ret i32 %3
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
