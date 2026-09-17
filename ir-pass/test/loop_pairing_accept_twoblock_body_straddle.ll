; loop_pairing_accept_twoblock_body_straddle.ll — ACCEPT, AND IT DISCHARGES.
; bd `test_C_libtooling-6n1s` (P1 OVER-ACCEPT, found by the Rule-13 review of
; 2026-09-18, closed the same day). THE RED HALF of that fix's red-green pair.
;
; SOURCE (`trackT2/probes/t5j_twoblock_noexit_rot.c`, `clang -O1`, no `-g`):
;
;     int slice(int lim) {
;         int y = cq_theta(5, 0.5);
;         int s = 0;
;         for (int k = 1; k <= 4; ++k) {
;             int d = (y >> k);
;             s += cq_measure(d & 1);
;             if (k < lim) s += cq_measure(d & 2);   /* re-joins; NO break */
;         }
;         y = cq_theta(y, 0.9);
;         return s + cq_measure(y);
;     }
;
; ⚠ WHAT THIS FILE PINS IS A PLACEMENT, AND THE DEFECT IT REPLACES WAS A WRONG
; UNITARY, NOT A LEAK. The body is MARKED iteration-local, so
; `declineDephasingUnmarkedLoopRails` conjunct (1) suppresses its fence; but the
; `ashr` rail's two consumers sit in DIFFERENT body blocks, and until 2026-09-18
; `planInteriorComponent`'s convergence loop DROPPED the rail because the
; conditional consumer does not DOMINATE the post-dominator the discharge anchors
; at. MEASURED on the session ORACLE `9bd01598d574b344`: FOUR
; `cq_template_ashr_i32_hl(h0,k)` mints, **ZERO `_unc` and ZERO `cqrt_free`**,
; standing across `cqrt_ry_i32(h0, 0.9)` and `cqrt_measure_i32(h0)`. Only one or
; two bits of each 32-bit rail are ever measured, so the rest stay ENTANGLED with
; `h0` at the interference — `CLAUDE.md` Rule 8, and §5's Q-R1-1 correction in
; the words that apply: *"rotated by a NON-DIAGONAL gate after the loop and then
; measured … it is a wrong unitary"*.
;
; ⚠ IT WAS A REGRESSION, MEASURED AND NOT INFERRED. On the 2026-09-14 pre-group
; binary `0e280fc62a91cec2` this module DECLINES (that release's spelling:
; `cq loop lowering: rolled body leaks a rail entangled with a register rotated
; after the loop`). At `74eabd2c` `markIfRailLocal` had exactly TWO call sites,
; both inside `collapseFlattenedLoopRails`, which returns early unless an in-loop
; region was flattened — and this program has NO tainted control flow, so nothing
; marked it. bd `test_C_libtooling-tu9q`'s round-1 root-mint escape added the
; THIRD call site in `lowerLoops`, which marks a body with no region in it.
;
; THE FIX IS A PLACEMENT, NOT A DECLINE (Rule 17). `useCompleteBeforeDischarge`
; (`Uncomputation.cpp`) asks the obligation this scan actually owes — *no use runs
; between the discharge and the NEXT execution of the mint* — instead of the
; strictly stronger dominance the shipped helper bundles with it, SCOPED to a use,
; a discharge and a mint that all sit in ONE marked body. Every gate whose ADJOINT
; is emitted is still re-proved under the full `DT.dominates(G, At)` in §4, so what
; is relaxed is only a READER the reversal never touches.
;
; WHAT TO READ IN THE CHECKS BELOW, in one sentence: the `_unc` and the `cqrt_free`
; land in the LATCH (`%11`), a DIFFERENT block from the mint (`%4`), and they run
; ONCE PER TRIP — which is the whole point, because a discharge in the mint's own
; block is the shape that already worked and is pinned by
; `loop_pairing_accept_oneblock_body_control.ll`.
;
; ⚠ STAGE 2b CANNOT WITNESS THIS FILE AND THAT IS STRUCTURAL, NOT A DEFECT.
; `free_pairing_check.py` analyses per STREAM — a maximal chain of blocks joined
; by unconditional single-predecessor edges — so a discharge at a JOIN point is
; `U3-extern-rail` UNPROVEN by construction (measured: `0 verified, 0 violation(s),
; 2 unproven`, where the single-block control reports `2 verified`). The rail
; identities it would check are pinned HERE instead, by position.
;
; ⚠ THE WARNING IS EXPECTED AND IS **NOT** ABOUT THE `ashr` RAILS. `opt` still
; prints `cq rotation lowering: non-diagonal gate over a live derived record`
; because the CONDITIONAL `cq_template_and_i32_hl(%h_op, 2)` rail's own
; `cqrt_measure` does not DOMINATE the post-loop rotation, so `recordIsExemptAt`
; clause 4 cannot exempt it. That is the same dominance-vs-conditional-execution
; shape this fix addresses, in a guard `RotationLowering.cpp` owns; it is FILED,
; not fixed here (a second spelling of another owner's predicate is the drbq
; Inc-3 (b′) defect, Rule 14).
;
; ⚠ RETIREMENT TRIGGER (L8): if `useCompleteBeforeDischarge`'s marked-body scoping
; is ever widened to acyclic regions, this file does NOT change — but
; `lowering_uncompute_interior_leak_*` will, and the two must be re-derived
; together. If this file ever goes back to `3/0`, the 6n1s regression is live.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=COUNT < %t.cqd0.ll
;
; The mint is in the loop header block; the two consumers straddle the header and
; the guarded block; the discharge lands in the LATCH.
; CHECK-LABEL: define i32 @slice
; CHECK: %h = call i32 @cqrt_alloc_i32(i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
; CHECK: %h_op = call i32 @cq_template_ashr_i32_hl(i32 %h, i32 %5)
; CHECK-NEXT: %h_op1 = call i32 @cq_template_and_i32_hl(i32 %h_op, i32 1)
; CHECK: br i1 %8, label %9, label %11
; CHECK: %h_op2 = call i32 @cq_template_and_i32_hl(i32 %h_op, i32 2)
; CHECK: br label %11
; CHECK: call void @cq_template_ashr_i32_hl_unc(i32 %h_op, i32 %h, i32 %5)
; CHECK-NEXT: call void @cqrt_free(i32 %h_op)
; CHECK: call void @cqrt_ry_i32(i32 %h, double 9.000000e-01)
;
; ONE mint, ONE adjoint, ONE free per trip — in their own whole-file prefix, so
; they cannot window a negative (Rule 12 fixture-hygiene defect (a)).
; COUNT-COUNT-1: call i32 @cq_template_ashr_i32_hl(
; COUNT-COUNT-1: call void @cq_template_ashr_i32_hl_unc(
; COUNT-COUNT-1: call void @cqrt_free(

; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-18-orchestrator/trackT2/probes/t5j_twoblock_noexit_rot.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-18-orchestrator/trackT2/probes/t5j_twoblock_noexit_rot.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2
  br label %7

3:                                                ; preds = %19
  %4 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 9.000000e-01) #2
  %5 = tail call i32 @cq_measure_si32(i32 noundef %4) #2
  %6 = add nsw i32 %5, %20
  ret i32 %6

7:                                                ; preds = %1, %19
  %8 = phi i32 [ 1, %1 ], [ %21, %19 ]
  %9 = phi i32 [ 0, %1 ], [ %20, %19 ]
  %10 = ashr i32 %2, %8
  %11 = and i32 %10, 1
  %12 = tail call i32 @cq_measure_si32(i32 noundef %11) #2
  %13 = add nsw i32 %12, %9
  %14 = icmp slt i32 %8, %0
  br i1 %14, label %15, label %19

15:                                               ; preds = %7
  %16 = and i32 %10, 2
  %17 = tail call i32 @cq_measure_si32(i32 noundef %16) #2
  %18 = add nsw i32 %17, %13
  br label %19

19:                                               ; preds = %15, %7
  %20 = phi i32 [ %18, %15 ], [ %13, %7 ]
  %21 = add nuw nsw i32 %8, 1
  %22 = icmp eq i32 %21, 5
  br i1 %22, label %3, label %7, !llvm.loop !6
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2
  br label %4

4:                                                ; preds = %16, %2
  %5 = phi i32 [ 1, %2 ], [ %18, %16 ]
  %6 = phi i32 [ 0, %2 ], [ %17, %16 ]
  %7 = ashr i32 %3, %5
  %8 = and i32 %7, 1
  %9 = tail call i32 @cq_measure_si32(i32 noundef %8) #2
  %10 = add nsw i32 %9, %6
  %11 = icmp sgt i32 %5, %0
  br i1 %11, label %16, label %12

12:                                               ; preds = %4
  %13 = and i32 %7, 2
  %14 = tail call i32 @cq_measure_si32(i32 noundef %13) #2
  %15 = add nsw i32 %14, %10
  br label %16

16:                                               ; preds = %12, %4
  %17 = phi i32 [ %15, %12 ], [ %10, %4 ]
  %18 = add nuw nsw i32 %5, 1
  %19 = icmp eq i32 %18, 5
  br i1 %19, label %20, label %4, !llvm.loop !6

20:                                               ; preds = %16
  %21 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 9.000000e-01) #2
  %22 = tail call i32 @cq_measure_si32(i32 noundef %21) #2
  %23 = add nsw i32 %22, %17
  ret i32 %23
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
