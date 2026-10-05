; lowering_reject_break_phase_answer_kickback.ll — DECLINE. bd
; test_C_libtooling-3qlq Inc 1, the Rule-13 CLEARANCE §4 (ii) finding: the B3
; fence `cq loop lowering: early break preserves a phase answer`
; (`LoopLowering.cpp` `kMsgBreakPhase`) is REACHABLE FROM PLAIN C under the
; register-free `cq_phi` surface, and NO fixture pinned it.
;
;     __attribute__((noinline))
;     int run(int seed, int n){ int q = seed; cq_theta(&q, 0.25);
;       if (q == 5) cq_phi(0.3);                  // a KICKBACK, before the loop
;       for (int i = 0; i < n; i++) { q = q ^ 5; if ((q & 1) == 0) break; }
;       return cq_measure(q); }
;
; That is the shipped 7.4 break loop of `tests/e2e/slice_loop_break.c` VERBATIM,
; with one kickback region placed before it. The module below is `clang -O1`'s
; output for it, with `@main` dropped (the source and the unedited stage-1 module
; are committed at
; `docs/prd/phase-04-swap-route-control/inc1-records/session-0a61aa31/clearance_c1/f1_break_kick_before.{c,subj.s1.ll}`).
;
; WHY IT DECLINES. `tryBreak` classifies the escaping answer's lineage: `%18`, the
; exit merge phi, has an incoming that is the register a `cq_phi` PHASED, so the
; answer is PHASE-class. The §2.2 capture is `cqrt_copy_<W>` — a CNOT — and a CNOT
; copies a BASIS LABEL, not a phase, so the index-gated capture + whole-loop
; reverse-play would DEPHASE exactly the answer the program computed (Rule 7, the
; canonical method-B-on-a-phase-arm miscompile). Over-declining is safe; this is
; the Prime Directive doing its job on a shape the surface change made ordinary.
;
; bd 3by9 (2026-10-05). B3 now asks the per-register `lineageCarriesBranchPhase`
; instead of "any branch phase in the function". This program still declines
; under it: the phase's controller `q == 5` reads `%3`, the rail root the
; escaping answer `%18` derives from. Its sibling with the kickback on the
; COMPARAND instead (`lowering_loop_break_qq_phase.ll`) now lowers. ⚠ THE
; PARAGRAPH ABOVE IS AN UNREVIEWED RATIONALE, NOT A PROOF: by linearity the
; construct (a basis permutation that restores the rail) carries a phase applied
; before it on the amplitude, and the copy-out's entanglement with the restored
; rail is the same for a phase-free superposed answer. The decline is kept at
; the scope bd 3by9 was given; whether it is an over-decline too is reported for
; owner review, so do not cite this file as evidence of a phase hazard.
;
; ⚠ WHY THIS FILE EXISTS BESIDE `lowering_reject_break_phase_answer.ll`. That file
; is the ORIGINAL B3 pin and it no longer reaches B3: after the round-2 carrier fix
; its module is pre-empted by `loop under quantum control`, so it now pins THAT
; fence (still a loud decline; only the string moved). Its header records the open
; question "whether ANY module can still reach `early break preserves a phase
; answer`" as UNCONFIRMED. This file ANSWERS it, from plain C, and pins the string
; character-for-character (Rule 12). MEASURED on BOTH binaries — the pre-fix
; subject 542d588 and the C-1 fix — via the full pipeline
; (`clang -O1` -> `cq-opt`): `opt` exits non-zero with exactly this message.
;
; ⚠ THE DISCRIMINATING CONTROL is `lowering_break_global_phase_before_accept.ll`
; (`f3`), the same program with the kickback replaced by an UNCONDITIONAL
; `cq_phi(0.3)` — a GLOBAL phase, DELETED by owner decision D2 — which ACCEPTS and
; lowers to the plain break loop. Without it this fence would be indistinguishable
; from "any `cq_phi` before a break loop declines", i.e. a wall rather than a
; discriminator.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: early break preserves a phase answer

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: noinline nounwind ssp uwtable
define i32 @run(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 2.500000e-01) #3
  %4 = icmp eq i32 %3, 5
  br i1 %4, label %5, label %6

5:                                                ; preds = %2
  tail call void @cq_phi(double noundef 3.000000e-01) #3
  br label %6

6:                                                ; preds = %5, %2
  %7 = icmp sgt i32 %1, 0
  br i1 %7, label %8, label %17

8:                                                ; preds = %6, %8
  %9 = phi i32 [ %14, %8 ], [ 0, %6 ]
  %10 = phi i32 [ %11, %8 ], [ %3, %6 ]
  %11 = xor i32 %10, 5
  %12 = and i32 %11, 1
  %13 = icmp eq i32 %12, 0
  %14 = add nuw nsw i32 %9, 1
  %15 = icmp eq i32 %14, %1
  %16 = select i1 %13, i1 true, i1 %15
  br i1 %16, label %17, label %8, !llvm.loop !6

17:                                               ; preds = %8, %6
  %18 = phi i32 [ %3, %6 ], [ %11, %8 ]
  %19 = tail call i32 @cq_measure_si32(i32 noundef %18) #3
  ret i32 %19
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind }

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
