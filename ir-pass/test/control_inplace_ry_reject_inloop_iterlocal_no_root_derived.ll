; control_inplace_ry_reject_inloop_iterlocal_no_root_derived.ll — DECLINE (bd
; `test_C_libtooling-wx8g`): a clause-(c) loop with NO LOOP-INVARIANT TAINTED
; REGISTER and a DERIVED condition, so the body mints a per-trip TEMPLATE rail
; that nothing would discharge.
;
;     for (k < 2) { int u = cq_theta(5, .5); int r = cq_theta(7, .25);
;                   if ((u >> 1) & 1) r = cq_theta(r, .2); … }
;
; CLAUSE (c) ADMITS IT AT DETECTION and the ROUND-2 RE-ASK refuses it, which is
; the whole reason that re-ask exists (CLAUDE.md's L1 "a stage that runs ONCE has
; a round-2-FALSE premise", one layer over). `LoopLowering::invariantRegisterRoots`
; returns false at its "no invariant register read" early-out — every tainted
; value here is defined INSIDE the loop — so `markIfRailLocal` is NEVER CALLED,
; `taint.IterationLocalBlocks` stays empty, and `Uncomputation`'s in-loop guard
; (`canRepeat(&BB) && !IterationLocalBlocks.count(&BB)`) SILENTLY SKIPS the
; body's interior candidates. The `cq_template_and_i32_hl` rail minted every trip
; would then never be `_unc`-reversed and never freed: one entangled which-path
; record of `u`'s bit leaked per activation, against a hand-unrolled twin that
; discharges all of them.
;
; ⚠ IT IS INVISIBLE TO EVERY OTHER GATE. `opt` exits 0, `opt -verify` is clean,
; and STRICT stage 2b reports `0 violation(s)` — `free_pairing_check.py` counts
; `cqrt_alloc` SITES and a template-minted rail has none, as its own header says.
; Only the rolled-vs-unrolled byte-diff, or this fence, can see it.
;
; ⚠ ITS DISCRIMINATING SIBLING IS AN ACCEPT:
; `control_inplace_ry_inloop_iterlocal_no_root.ll` is this same shape with a bare
; `_Bool` condition, which mints NOTHING — so its body has no spine-discharge
; candidate, the missing marking changes no stream, and it lowers. One `&`
; between the two files, two dispositions.
;
; RETIREMENT TRIGGER (L8): this becomes an ACCEPT the day `invariantRegisterRoots`
; (or whatever succeeds it) can hand `markIfRailLocal` a root for a loop whose
; every register is iteration-local, OR the day the whole-DAG spine learns to
; discharge an iteration-local template rail without the block marking. Re-derive
; the stream then — one `alloc`/`ry` pair, one `and`, one `icmp`, one controlled
; Ry, then `icmp_unc`, `free`, `and_unc`, `free` — do not delete this file.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; ⚠ A `DS_Error` decline writes ZERO bytes to stdout, so an IR-text `CHECK-NOT`
; here would be VACUOUS; the property is pinned by the `not` INVERSION on the RUN
; line plus the string below, mirrored character-for-character against `ir-pass/src`.
; CHECK: error{{.*}}control flow inside a loop body under quantum control
;
; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/probes/w_j_no_invariant_root_derived.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/probes/w_j_no_invariant_root_derived.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 {
  br label %2

1:                                                ; preds = %11
  ret i32 %16

2:                                                ; preds = %0, %11
  %3 = phi i32 [ 0, %0 ], [ %16, %11 ]
  %4 = phi i32 [ 0, %0 ], [ %17, %11 ]
  %5 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2
  %6 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 2.500000e-01) #2
  %7 = and i32 %5, 2
  %8 = icmp eq i32 %7, 0
  br i1 %8, label %11, label %9

9:                                                ; preds = %2
  %10 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef 2.000000e-01) #2
  br label %11

11:                                               ; preds = %9, %2
  %12 = phi i32 [ %10, %9 ], [ %6, %2 ]
  %13 = tail call i32 @cq_measure_si32(i32 noundef %12) #2
  %14 = tail call i32 @cq_measure_si32(i32 noundef %5) #2
  %15 = add i32 %13, %3
  %16 = add i32 %15, %14
  %17 = add nuw nsw i32 %4, 1
  %18 = icmp eq i32 %4, 0
  br i1 %18, label %2, label %1, !llvm.loop !6
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  br label %1

1:                                                ; preds = %10, %0
  %2 = phi i32 [ 0, %0 ], [ %15, %10 ]
  %3 = phi i32 [ 0, %0 ], [ %16, %10 ]
  %4 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2
  %5 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 2.500000e-01) #2
  %6 = and i32 %4, 2
  %7 = icmp eq i32 %6, 0
  br i1 %7, label %10, label %8

8:                                                ; preds = %1
  %9 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 2.000000e-01) #2
  br label %10

10:                                               ; preds = %8, %1
  %11 = phi i32 [ %9, %8 ], [ %5, %1 ]
  %12 = tail call i32 @cq_measure_si32(i32 noundef %11) #2
  %13 = tail call i32 @cq_measure_si32(i32 noundef %4) #2
  %14 = add i32 %12, %2
  %15 = add i32 %14, %13
  %16 = add nuw nsw i32 %3, 1
  %17 = icmp eq i32 %3, 0
  br i1 %17, label %1, label %18, !llvm.loop !6

18:                                               ; preds = %10
  ret i32 %15
}

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
