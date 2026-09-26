; lowering_classical_mux_phi_onereg_spec_scrubbed_base_degenerate.ll — ACCEPT (bd
; ⚠ bd test_C_libtooling-vsfp (2026-09-26) — RE-SPELLED, and why. `@h` used to
; IGNORE its parameter 0. `dropDeadCallArguments` (SpecializeDetect.h) now replaces an
; integer/fp argument whose callee parameter has NO USES by a constant before any
; stage reads it — what `clang -O1` does to the hand-inlined twin — so that spelling
; is no longer a Phase-6 site at all: the call stays an ordinary classical call, no
; clone is built and nothing is scrubbed, i.e. the property this file pins would have
; no subject. The added lines in `@h` (a branch-only read — see ROUND 2 below) keep the
; parameter live, so the clone is still built, still returns classical and is
; still scrubbed. (The clone's own flatten removes the read, so the clone body carries no
; template for it; the caller-side checks below are unchanged.)
; That population — a callee that READS the
; argument yet returns classical — is IR-ONLY from C at -O1. The NODROP prefix pins
; that the drop does NOT fire here; a widening of the drop retires this subject and
; must re-derive it (CLAUDE.md L8).
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
; test_C_libtooling-d88e, the re-ask's NO-TAINTED-INCOMING branch). HAND-EDITED IR.
;
; `lowering_reject_classical_mux_phi_spec_scrubbed_base.ll` with the arm's
; `cq_theta` deleted and the merge rewritten to the DEGENERATE `phi(t, t)`: every
; incoming IS the base, every wire chain is empty. `clang -O1` never emits this
; (InstCombine folds it), so it is reachable only as IR — which is why it is a
; hand-edit of the generated module and not a C program.
;
; The lift still fires (every incoming is the conservatively-tainted `t`, one
; base, no gate to prove) and `specialize()` still scrubs `t`. The re-ask
; (`declineFalsifiedMergePhiLifts`) must NOT decline it: RAUW'ing `phi(t, t)` to
; `t` is exact whatever `t`'s taint, and the hand-inlined twin (`%7 = add nsw i32
; %5, 1` in place of the call — measured on main `def1b088`) keeps the phi as a
; CLASSICAL phi (`readsTaintedValue` is false, `declineClassicalMuxes` skips it)
; and ACCEPTS with the same gate stream: Ry(.5) on `q`, no measurement (the
; `cq_measure` of a classical value is the bd 21mg identity). The re-ask mirrors
; that: when NO recorded incoming is tainted at FINAL taint, the twin would never
; have asked, so neither does the re-ask. Deleting that branch turns this red.
;
; RUN: env CQ_DEADARG_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2> %t.vsfp.err \
; RUN:   | %filecheck %s
; RUN: %filecheck %s --check-prefix=NODROP --allow-empty < %t.vsfp.err
; NODROP-NOT: CQ_DEADARG_DBG
; CHECK-LABEL: define i32 @main(
; CHECK:      [[Q:%[a-z0-9.]+]] = call i32 @cqrt_alloc_i32(i32 %5)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 [[Q]], double 5.000000e-01)
; (bd vsfp round 3, bd tzfa: slot 0 is one the specializer RECORDED dead — the clone never
; reads it — so `resolvePhantomCloneArgReads` NEUTRALISES it to `0` after `specialize()`;
; the operand is a `cq_theta` result, which the twin keeps, so nothing is declined.)
; CHECK-NEXT: [[T:%[0-9]+]] = tail call i32 @__cq_q_h_01(i32 noundef 0, i32 noundef %5)
; CHECK-NOT:  cqrt_
; CHECK:      ret i32 [[T]]
; CHECK-NEXT: }

; ModuleID = 'llvm-link'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #0 {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8, !tbaa !6
  %5 = tail call i32 @atoi(ptr nocapture noundef %4)
  %6 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 5.000000e-01) #4
  %7 = tail call i32 @h(i32 noundef %6, i32 noundef %5) #4
  %8 = icmp sgt i32 %5, 3
  br i1 %8, label %9, label %11

9:                                                ; preds = %2
  br label %11

11:                                               ; preds = %9, %2
  %12 = phi i32 [ %7, %9 ], [ %7, %2 ]
  %13 = tail call i32 @cq_measure_si32(i32 noundef %12) #4
  ret i32 %13
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
