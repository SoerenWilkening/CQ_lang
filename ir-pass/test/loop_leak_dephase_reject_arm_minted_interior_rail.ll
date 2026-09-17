; loop_leak_dephase_reject_arm_minted_interior_rail.ll — DECLINE. bd
; `test_C_libtooling-6n1s`, finding **F-1** of the independent Rule-13 round of
; 2026-09-18. THE RED HALF of that fix's red-green pair.
;
; SOURCE (`trackT2/probes/g8_arm_use_derived_owned_rot.c`, `clang -O1`, no `-g`):
;
;     for (int k = 1; k <= 4; ++k) {
;         int d = (y >> k);
;         s += cq_measure(d & 1);
;         if (k < lim) { int e = d + 7; s += cq_measure(e & 2); }  /* re-joins */
;     }
;     y = cq_theta(y, 0.9);
;     return s + cq_measure(y);
;
; ⚠ **THIS IS bd `6n1s` AGAIN, ONE TOKEN AWAY FROM THE WITNESS THAT INCREMENT
; CLOSED, AND IT SURVIVED THE FIRST FIX.** Measured on FOUR binaries: DECLINE on
; the pre-group `0e280fc62a91cec2`; ACCEPT at exit 0 with 4
; `cq_template_ashr_i32_hl` mints, **ZERO `_unc`**, **ZERO `cqrt_free`**, then
; `cqrt_ry_i32(h0,0.9)` and `cqrt_measure_i32(h0)` on the session ORACLE
; `9bd01598`, on the bd-`6n1s`+P1+P2 subject `7c1163ad`, **and** on the P0+P3
; branch `e951d5d1`. Stage 2b `2 left dirty, 0 cqrt_free site(s)` at exit 0 on all
; three. Four full 32-bit coherent copies of `y >> k` stand at a NON-DIAGONAL gate
; on the register they copy, and that register is the program's observable —
; `CLAUDE.md` Rule 8, and §5's Q-R1-1 correction verbatim.
;
; ⚠ **WHY THE FIRST FIX MISSED IT, because "the fence did not fire" is not a
; mechanism.** Conjunct (1) of `declineDephasingUnmarkedLoopRails` suppressed on
; `bodyBlocksMarked && markedBodyRailsHaveInBodyDischargePoint`, and BOTH are true
; here: the body is marked, and the post-dominator fold over `{%4, %9}` is the
; join `%11`, an own block of `L`. The rails still leak, because
; `Uncomputation::planInteriorComponent` §4 abandons the WHOLE component on the
; per-gate `DT.dominates(G, At)` — the ARM's producer `%h_op2 =
; cq_template_add_i32_hl(%h_op, 3)` sits in `%9`, which does not dominate the join.
; **The fence modelled ONE refusal mechanism and a multi-block body produces a
; DIFFERENT one BY CONSTRUCTION.** A prediction about another file's placement is
; not a fence.
;
; THE FIX IS PREDICT-AND-VERIFY, not a wider prediction: conjunct (1) now RECORDS
; the suppression and `declineUndischargedMarkedBodyRails` checks it at the tail of
; the pass — after `uncompute`, in BOTH entry points — where the discharge is a
; FACT. The message is the EXISTING bd `s82e` string, so this file joins that
; fence's pins rather than starting a new family.
;
; ⚠ **THE ISOLATION IS ONE TOKEN AND IT NAMES THE DISCRIMINANT.**
; `loop_pairing_accept_arm_minted_measure_owned_control.ll` is this module with
; `& 2` deleted from the arm, making the arm's rail MEASURE-OWNED instead of
; INTERIOR — it ACCEPTS and discharges 4/4. So the cause is *"the ARM mints an
; INTERIOR rail"*, not the second block, not the fan-out and not the interference.
; `loop_leak_dephase_reject_arm_minted_unmarked_control.ll` (same shape, marking
; refused) DECLINES on every binary, so the MARKING is the door.
;
; ⚠ RULE-12 HYGIENE (b): a `DS_Error` decline writes ZERO bytes to stdout, so the
; property below is pinned by the `not` inversion on the RUN line and by the
; message match, NOT by any IR-text check. Do not add `CHECK-NOT`s over lowered IR
; here and read them as coverage.
;
; ⚠ RETIREMENT TRIGGER (L8): this becomes an ACCEPT the day the interior partition
; can discharge an ARM-MINTED rail at a proven per-trip point — the placement fix
; (a) the reviewer ranked first. It needs a component partition FINER than a
; component (split `{d}` from `{e}` by control-equivalence, not by multiplicity —
; both are in the same marked body, so bd `tu9q` P0's key does not separate them)
; PLUS a per-activation cross-plan ordering check, because `{e}`'s adjoint in the
; arm READS `d` while `{d}`'s free is at the join and the arm does not DOMINATE the
; join. Re-derive the stream then — it is the hand-unrolled twin's — and do not
; delete this file.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
;
; CHECK: cq loop lowering: rolled body leaks a rail entangled with a rotated register

; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-18-orchestrator/trackT2/probes/g8_arm_use_derived_owned_rot.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-18-orchestrator/trackT2/probes/g8_arm_use_derived_owned_rot.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2
  br label %7

3:                                                ; preds = %20
  %4 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 9.000000e-01) #2
  %5 = tail call i32 @cq_measure_si32(i32 noundef %4) #2
  %6 = add nsw i32 %5, %21
  ret i32 %6

7:                                                ; preds = %1, %20
  %8 = phi i32 [ 0, %1 ], [ %21, %20 ]
  %9 = phi i32 [ 1, %1 ], [ %22, %20 ]
  %10 = ashr i32 %2, %9
  %11 = and i32 %10, 1
  %12 = tail call i32 @cq_measure_si32(i32 noundef %11) #2
  %13 = add nsw i32 %12, %8
  %14 = icmp slt i32 %9, %0
  br i1 %14, label %15, label %20

15:                                               ; preds = %7
  %16 = add i32 %10, 3
  %17 = and i32 %16, 2
  %18 = tail call i32 @cq_measure_si32(i32 noundef %17) #2
  %19 = add nsw i32 %18, %13
  br label %20

20:                                               ; preds = %15, %7
  %21 = phi i32 [ %19, %15 ], [ %13, %7 ]
  %22 = add nuw nsw i32 %9, 1
  %23 = icmp eq i32 %22, 5
  br i1 %23, label %3, label %7, !llvm.loop !6
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2
  br label %4

4:                                                ; preds = %17, %2
  %5 = phi i32 [ 0, %2 ], [ %18, %17 ]
  %6 = phi i32 [ 1, %2 ], [ %19, %17 ]
  %7 = ashr i32 %3, %6
  %8 = and i32 %7, 1
  %9 = tail call i32 @cq_measure_si32(i32 noundef %8) #2
  %10 = add nsw i32 %9, %5
  %11 = icmp sgt i32 %6, %0
  br i1 %11, label %17, label %12

12:                                               ; preds = %4
  %13 = add i32 %7, 3
  %14 = and i32 %13, 2
  %15 = tail call i32 @cq_measure_si32(i32 noundef %14) #2
  %16 = add nsw i32 %15, %10
  br label %17

17:                                               ; preds = %12, %4
  %18 = phi i32 [ %16, %12 ], [ %10, %4 ]
  %19 = add nuw nsw i32 %6, 1
  %20 = icmp eq i32 %19, 5
  br i1 %20, label %21, label %4, !llvm.loop !6

21:                                               ; preds = %17
  %22 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 9.000000e-01) #2
  %23 = tail call i32 @cq_measure_si32(i32 noundef %22) #2
  %24 = add nsw i32 %23, %18
  ret i32 %24
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
