; control_phase_kickback_mixed_preheader_r2derived_imm_outofplace.ll — ACCEPT. bd
; test_C_libtooling-3qlq Inc 1, the THIRD C-1 review round, finding **F-C1B-1**
; (CONFIRMED MISCOMPILE, introduced by the SECOND round's own fix).
;
;     int ext_f(int a);                          /* separate TU: return a + 100; */
;     int slice(int u){ int q=cq_theta(u,0.5); int r=cq_theta(u,0.3);
;       int y=5; if (q>5) y=ext_f(7);            /* 6.5 arm -> %out, tainted at emission */
;       int w = y * 3;                           /* DERIVED: untainted until ROUND 2     */
;       int a = cq_theta(u,0.7);
;       a = a + w;                               /* EXACTLY ONE tainted operand at ROUND 1 */
;       for(int i=0;i<3;i++){ if((a>>i)&1) cq_phi(0.2); r=cq_theta(r,0.1); }
;       return cq_measure(a)+cq_measure(r)+cq_measure(y); }
;
; `clang -O1`, `llvm-link`ed with the second TU, `@main` dropped. `!llvm.loop` kept.
;
; WHAT WENT WRONG. Round 2's `commitOutOfLoopInPlaceOps` asks
; `ArithLowering::classifyInPlaceReassignment` at the ROUND-1
; `collapseFlattenedLoopRails` call and writes the answer into
; `taint.InPlaceRailOps` as a COMMITMENT — and `lowerOps` honours it
; unconditionally (`:263` skips M-C for a marked op, `:350` routes it to
; `rewriteInPlaceValueRail`, which never re-asks the shape). But
; `repropagateControlMerges` runs in between and GROWS `taint.Tainted`: `%out` is
; tainted at emission, everything DERIVED from it only at ROUND 2. So G2's
; "exactly one tainted operand" was TRUE when asked and FALSE when used, and the
; emitted gate was
;
;     call void @cqrt_addc_i32(i32 %h4, i32 %h_op)      ; h_op = the `y*3` RAIL
;
; — a QUANTUM RAIL HANDLE IN THE ABI'S CLASSICAL-IMMEDIATE SLOT, which the trace
; runtime prints as the bare decimal `6` (`h6`'s handle id). The circuit computes
; `a + 6` where the source says `a + 3*y`; the `3*y` rail is left allocated with
; nothing uncomputing it; and `cq_measure(a)` measures a register never entangled
; with `y` at all. `opt` exit 0, verify-clean, STRICT stage 2b `0 violation(s)` —
; 2b's rule (A1) examines the immediate slot per-rail at a `cqrt_free`, and `%h4`
; is MEASURED rather than freed, so its write set is never looked at.
;
; ⭐ THE LESSON IS 8h7d.5's, A FIFTH TIME: **`P->hasOneUse()` was asked of `P`, and
; the answer that went stale was about `Imm`.** Round 2's stability conjunct
; reasons entirely about G6/G7 (a later READ of the parent); the commit also
; predicts G2, the SHAPE, and nothing guarded it. When you widen a set, ask what
; OTHER predicate was computed over the same closure.
;
; THE FIX IS MONOTONE AND ONE LINE: the commit now requires `isa<Constant>(Imm)`.
; A `Constant` can never become tainted — CHECKED, not assumed
; (`IOSinkLowering.cpp:295` enumerates every `taint.Tainted.insert(` site;
; re-measured at this HEAD, 35 sites, all `CallInst`/`Instruction`/`Argument`).
; A second, independent net rides with it: every committed op is recorded in
; `taint.PreLoopCommittedInPlaceOps` and RE-ASKED at `lowerOps` under final taint
; and a final CFG, declining loudly on a changed answer — see
; `control_phase_kickback_reject_preloop_commit_stale.ll`.
;
; ⭐ WHAT THIS FIXTURE ASSERTS is the CORRECT stream, which is 542d588's and the
; round-1 fix's byte for byte (47 trace lines, MEASURED): the Q+Q
; `cq_template_add_i32`, the `mul` rail discharged and freed, and NO `cqrt_addc`
; anywhere. It is RED on the round-2 binary and GREEN on 542d588, on the round-1
; fix and here — a narrowing fixture, not a capability one.
;
; ⚠ THE PER-TRIP `and` RAIL STILL LEAKS HERE, deliberately: the loop's invariant
; register is a `cq_template_add_i32` TEMPLATE rail, so `invariantRegisterRoots`
; clause (ii) refuses it. That is owner question Q-R1-1, unchanged by this round,
; and the `UCNT` block below pins it so a future widening of that clause has to
; look at this file.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=PCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=UCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MDCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RYCNT < %t.cqd0.ll

; The 6.5 classical-call arm's out-rail, then the ROUND-2-derived `y*3` rail.
; CHECK: %[[OUT:.*]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK: %[[MUL:.*]] = call i32 @cq_template_mul_i32_hl(i32 %[[OUT]], i32 3)

; ⭐ THE DISCRIMINATOR. `a + w` is a Q+Q add and must be lowered OUT OF PLACE into
; a fresh rail — never an in-place gate whose second argument is a rail handle.
; CHECK-NEXT: %[[A:.*]] = call i32 @cqrt_alloc_i32(
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[A]], double 0x3FE6666666666666)
; CHECK-NEXT: %[[SUM:.*]] = call i32 @cq_template_add_i32(i32 %[[A]], i32 %[[MUL]])

; ⭐ AND THE `y*3` RAIL IS DISCHARGED AND FREED — on the round-2 binary neither
; line existed, because the rail had been consumed as an "immediate".
; CHECK-NEXT: call void @cq_template_mul_i32_hl_unc(i32 %[[MUL]], i32 %[[OUT]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[MUL]])

; The rolled body reads the OUT-OF-PLACE sum rail.
; CHECK: call i32 @cq_template_and_i32_hl(i32 %[[SUM]], i32 %{{.*}})

; ⭐ ZERO in-place value gates in the whole module. This is the assertion the
; finding is about; `cqrt_addc_i32` appeared exactly once on the round-2 binary.
; PCNT-NOT: call void @cqrt_addc_i32(
; PCNT-NOT: call void @cqrt_xorc_i32(

; The Q-R1-1 residual, pinned: the per-trip `and` rail is minted and NOT
; discharged (the invariant register is a template rail, clause (ii) refuses it).
; UCNT-COUNT-1: call i32 @cq_template_and_i32_hl(
; UCNT-NOT: call i32 @cq_template_and_i32_hl(
; UCNT-NOT: call void @cq_template_and_i32_hl_unc(

; ONE kickback gate in the rolled body.
; ACNT-COUNT-1: call void @cqrt_rz_i1(
; ACNT-NOT: call void @cqrt_rz_i1(

; `#cqrt_rz_i1 == #!cq.branchphase`.
; MDCNT-COUNT-1: !cq.branchphase
; MDCNT-NOT: !cq.branchphase

; The `cqrt_free` census — a dropped or an extra free is a Rule-6 defect the
; positive CHECKs cannot see.
; FCNT-COUNT-3: call void @cqrt_free(
; FCNT-NOT: call void @cqrt_free(

; The `cqrt_x` census: the kickback's polarity bracket(s) and the arm brackets.
; An UNPAIRED one is a wrong-branch phase.
; XCNT-COUNT-4: call void @cqrt_x(i32
; XCNT-NOT: call void @cqrt_x(i32

; bd 3qlq, the FOURTH C-1 round, lens finding F-C1D-4: the Ry budget.
; NOTHING may add an uncontrolled `cqrt_ry` on a register under quantum
; control — a non-diagonal gate there is a different unitary, and before this
; prefix an injected one was caught by 0 of this file's prefixes.
; RYCNT-COUNT-4: call void @cqrt_ry_
; RYCNT-NOT: call void @cqrt_ry_

; WHOLE-FILE PURE-NEGATIVE.
; NOROUTE-NOT: @cqrt_cswap
; NOROUTE-NOT: @cq_phi
; NOROUTE-NOT: @cq_theta
; NOROUTE-NOT: call void @cqrt_rz_{{(i8|i16|i32|i64|f16|f32|f64|f80)}}(
; NOROUTE-NOT: @cqrt_rz_{{[a-z0-9]+}}_controlled(
; NOROUTE-NOT: call void @cqrt_addc_i32(i32 %{{[A-Za-z0-9_.]+}}, i32 %
; NOROUTE-NOT: call void @cqrt_xorc_i32(i32 %{{[A-Za-z0-9_.]+}}, i32 %

; ModuleID = 'llvm-link'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #3
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 3.000000e-01) #3
  %4 = icmp sgt i32 %2, 5
  br i1 %4, label %5, label %7

5:                                                ; preds = %1
  %6 = tail call i32 @ext_f(i32 noundef 7) #3
  br label %7

7:                                                ; preds = %5, %1
  %8 = phi i32 [ %6, %5 ], [ 5, %1 ]
  %9 = mul nsw i32 %8, 3
  %10 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 0x3FE6666666666666) #3
  %11 = add nsw i32 %10, %9
  br label %18

12:                                               ; preds = %25
  %13 = tail call i32 @cq_measure_si32(i32 noundef %11) #3
  %14 = tail call i32 @cq_measure_si32(i32 noundef %26) #3
  %15 = add nsw i32 %14, %13
  %16 = tail call i32 @cq_measure_si32(i32 noundef %8) #3
  %17 = add nsw i32 %15, %16
  ret i32 %17

18:                                               ; preds = %25, %7
  %19 = phi i32 [ 0, %7 ], [ %27, %25 ]
  %20 = phi i32 [ %3, %7 ], [ %26, %25 ]
  %21 = shl nuw nsw i32 1, %19
  %22 = and i32 %21, %11
  %23 = icmp eq i32 %22, 0
  br i1 %23, label %25, label %24

24:                                               ; preds = %18
  tail call void @cq_phi(double noundef 2.000000e-01) #3
  br label %25

25:                                               ; preds = %24, %18
  %26 = tail call i32 @cq_theta_si32(i32 noundef %20, double noundef 1.000000e-01) #3
  %27 = add nuw nsw i32 %19, 1
  %28 = icmp eq i32 %27, 3
  br i1 %28, label %12, label %18, !llvm.loop !6
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483548, -2147483648) i32 @ext_f(i32 noundef %0) local_unnamed_addr #2 {
  %2 = add nsw i32 %0, 100
  ret i32 %2
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind }

!llvm.ident = !{!0, !0}
!llvm.module.flags = !{!1, !2, !3, !4, !5}

!0 = !{!"Homebrew clang version 19.1.7"}
!1 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}
!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
