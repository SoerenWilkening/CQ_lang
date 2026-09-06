; control_phase_kickback_reject_preloop_commit_stale.ll — DECLINE. bd
; test_C_libtooling-3qlq Inc 1, the THIRD C-1 review round, finding **F-C1C-1**:
; a SECOND CONFIRMED SILENT MISCOMPILE in the second round's commit, in the very
; half its `hasOneUse` conjunct was written to close.
;
;     int slice(int u){ int q=cq_theta(u,0.5); int r=cq_theta(u,0.3);
;       int q2=cq_theta(q,0.3);          /* the SAME WIRE, a SECOND SSA name for it */
;       int a = q2 + 7;                  /* P = %q2, which really does have ONE use */
;       for(int i=0;i<3;i++){ if((a>>i)&1) cq_phi(0.2); r=cq_theta(r,0.1); }
;       return cq_measure(q)+cq_measure(r)+cq_measure(a); }
;                    ^^^^^^^^^^^^^^^^ a LATER read of the PRE-op name
;
; `clang -O1`, `@main` dropped. `!llvm.loop` kept VERBATIM.
;
; THE DEFECT. `commitOutOfLoopInPlaceOps` predicts M-C's answer at `lowerLoops`
; and `lowerOps` then honours the marking UNCONDITIONALLY. Its stability conjunct
; is `P->hasOneUse()`, argued as *"no later stage invents a read of a value that
; has none"*. That is true of the SSA VALUE and **FALSE OF THE WIRE**:
; `lowerRotations` RAUWs every member of a theta chain onto the ONE `cqrt_alloc`
; handle, so by `lowerOps` the parent is `%h`, whose user set is the UNION of
; `%q`'s and `%q2`'s. `hasOneUse` was asked of `%q2`; the read that makes the
; in-place choice wrong is a use of `%q`.
;
; MEASURED, and the twin is the witness. On the round-2 binary the emitted stream
; is `cqrt_addc_i32(h0, 7)` and the three measures are `h0`, `h1`, **`h0`** — `q`
; and `a` collapse onto ONE register, 39 trace lines, `opt` exit 0, verify-clean,
; STRICT stage 2b `0 violation(s)`. On 542d588 AND on the round-1 fix it is
; `cq_template_add_i32_hl(h0, 7) -> h2` with measures `h0`, `h1`, **`h2`** (33
; lines) — M-C's own G6/G7 refuse the in-place form there, correctly. The
; HAND-UNROLLED spelling of this source emits the out-of-place stream on ALL FOUR
; binaries including the round-2 one, so rolled and unrolled compute DIFFERENT
; VALUES there and the unrolled one is right.
;
; THE FIX IS (1b), AND IT IS A RE-VERIFICATION RATHER THAN A BETTER PREDICTION.
; Every op `commitOutOfLoopInPlaceOps` marks is recorded in
; `taint.PreLoopCommittedInPlaceOps`; `lowerOps` Phase 1 re-asks the ONE fence
; (`ArithLowering::classifyInPlaceReassignment`, with only G5's self-marking
; disjunct suppressed) under the FINAL `DominatorTree`/`LoopInfo` and the FINAL
; taint, and declines loudly when the answer has changed.
;
; ⚠ NOT A SILENT FALLBACK TO OUT-OF-PLACE, and that is the whole reason it is a
; diagnostic (Rule 1 — no third path). The commit is what licensed
; `markIfRailLocal` to mark the loop body, and that permission is already in
; `taint.IterationLocalBlocks`; lowering this one op out of place would leave the
; body marked on a premise that no longer holds, reading a fresh
; `cq_template_add_i32_hl` TEMPLATE rail (the Q-R1-1 class). Lowering nothing and
; exiting non-zero is the only disposition that keeps the two consistent.
;
; COST, stated: this is a NEW LOUD DECLINE for a program 542d588 accepted (and
; leaked). Prime-Directive direction; recorded in PRD §0 E2 and notes §3.11, with
; the one-token workaround pinned as the ACCEPT control
; `control_phase_kickback_mixed_preheader_chained_root_inloop.ll` — the same
; program with `cq_measure(q)` dropped, which still COMPILES and still discharges
; all three per-trip rails.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: pre-loop in-place op no longer provable at lowering

; NOTHING is lowered: no in-place gate, and no out-of-place fallback for the op
; either (the module never reaches the emitter).
; CHECK-NOT: cqrt_addc_i32
; CHECK-NOT: cq_template_add_i32_hl

; ModuleID = 'p/y1_preadd_chained_prerecord.c'
source_filename = "p/y1_preadd_chained_prerecord.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #2
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 3.000000e-01) #2
  %4 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 3.000000e-01) #2
  %5 = add nsw i32 %4, 7
  br label %12

6:                                                ; preds = %19
  %7 = tail call i32 @cq_measure_si32(i32 noundef %2) #2
  %8 = tail call i32 @cq_measure_si32(i32 noundef %20) #2
  %9 = add nsw i32 %8, %7
  %10 = tail call i32 @cq_measure_si32(i32 noundef %5) #2
  %11 = add nsw i32 %9, %10
  ret i32 %11

12:                                               ; preds = %1, %19
  %13 = phi i32 [ 0, %1 ], [ %21, %19 ]
  %14 = phi i32 [ %3, %1 ], [ %20, %19 ]
  %15 = shl nuw nsw i32 1, %13
  %16 = and i32 %15, %5
  %17 = icmp eq i32 %16, 0
  br i1 %17, label %19, label %18

18:                                               ; preds = %12
  tail call void @cq_phi(double noundef 2.000000e-01) #2
  br label %19

19:                                               ; preds = %18, %12
  %20 = tail call i32 @cq_theta_si32(i32 noundef %14, double noundef 1.000000e-01) #2
  %21 = add nuw nsw i32 %13, 1
  %22 = icmp eq i32 %21, 3
  br i1 %22, label %6, label %12, !llvm.loop !6
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
