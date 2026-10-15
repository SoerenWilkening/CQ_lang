; control_phase_kickback_onward_inloop.ll — ACCEPT. bd test_C_libtooling-3qlq
; Inc 1, Rule-13 ROUND-2 finding F-R1-1 (a CONFIRMED rolled≠unrolled divergence).
; THE ONWARD HALF: an in-loop kickback region whose condition reads a 6.5
; classical-call-arm `%out` rail, i.e. a region NO stage sees until ROUND 2.
;
;     int ext_f(int a);                                 // separate TU
;     int q = 3; cq_theta(&q, 0.5);
;     int y = 5; if (q > 5) y = ext_f(7);               // 6.5 arm  ->  %out
;     for (int i = 0; i < 3; ++i)
;         if (((y >> i) & 1)) cq_phi(0.25);             // D4's per-bit idiom
;     return cq_measure(y);
;
; `clang -O1` on that source, `llvm-link`ed with `int ext_f(int a){return a+100;}`,
; `@main` dropped. The `!llvm.loop` metadata is kept VERBATIM — this is a genuine
; ROLLED loop, and `llvm.loop.unroll.disable` is what keeps it one.
;
; WHAT WENT WRONG, AND IT IS A STAGE-ORDER BUG, NOT A MISSING CLAUSE.
; `collapseFlattenedLoopRails` — the ONLY caller of `invariantRegisterRoots` and
; `markIfRailLocal` — ran EXACTLY ONCE, at `CQLoweringPass.cpp`'s slot right after
; `lowerControlRegions`, which is BEFORE `repropagateControlMerges`. This region
; is claimed and flattened INSIDE that function, by yn71's
; `detectAndLowerOnwardControl`; at round 1 the register `%out` is not even
; TAINTED (that is what "onward" means). So the body was never marked
; iteration-local and `Uncomputation`'s in-loop guard silently skipped every
; interior candidate in it. MEASURED at `c4bd888`: THREE
; `cq_template_and_i32_hl` mints and **ZERO** `_unc` discharges — three entangled
; which-path records of `y`'s bits leaked per activation, at `opt` exit 0,
; verify-clean, and STRICT stage 2b `0 violation(s)` (the checker is structurally
; blind to a leaked TEMPLATE-minted rail: it has no `cqrt_alloc` to count). The
; hand-unrolled spelling of the same source discharged all three, so rolled and
; unrolled were DIFFERENT UNITARIES — the 8h7d.5 F-4 signature that round 1
; graded CONFIRMED as F-L7-2 on the flat surface.
;
; THE FIX, and why it is one stage and not two: `repropagateControlMerges` now
; calls the SAME `collapseFlattenedLoopRails` again at its end, handed the
; snapshot of `taint.InLoopFlattenedPreds` it took on entry, so the onward pass
; processes exactly the loops ROUND 2 opened and every pre-round-2 module is
; byte-identical. `invariantRegisterRoots` clause (ii-b) then admits the `%out`
; rail as a Root on clause (ii)'s OWN proof (`ChainWalk`'s (I1) needs
; `isTemplateProducer` + a `cq_template_` callee; `%out` is a `cqrt_alloc_i32`
; call and fails both, so no interior `At` can ever be placed for it).
;
; WITNESS — the trace of this program is now BYTE-IDENTICAL to the hand-unrolled
; twin's (40 lines each; it was 34 vs 40). That is the 8h7d.5 witness, and it is
; the one this file stands in for at the lit layer.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=UCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RYCNT < %t.cqd0.ll

; The 6.5 classical-call arm lowers first (round 1), minting the `%out` rail.
; CHECK: %[[OUT:.*]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK: call void @cqrt_xorc_i32_controlled(
; CHECK: call void @cq_template_icmp_sgt_i32_hl_unc(

; THE ROLLED BODY, in full and in order: mint the bit rail, mint the flag, the
; ¬flag bracket, the kickback gate, the flag strip+free — AND the per-iteration
; discharge of the bit rail, which is the whole finding.
; CHECK: %[[A:.*]] = call i32 @cq_template_and_i32_hl(i32 %[[OUT]], i32 %{{.*}})
; CHECK-NEXT: %[[F:.*]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[A]], i32 0)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F]], double 2.500000e-01), !cq.branchphase
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[A]], i32 0)
; CHECK-NEXT: call void @cq_template_and_i32_hl_unc(i32 %[[A]], i32 %[[OUT]], i32 %{{.*}})
; CHECK-NEXT: call void @cqrt_free(i32 %[[A]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])

; ⭐ THE ASSERTION THE FINDING IS ABOUT. Exactly ONE `and` discharge, in the
; ROLLED body (the loop runs it K times). It was ZERO before the fix, and every
; other directive in this file passed at that HEAD — so this count is the
; discriminator, not the decoration.
; UCNT-COUNT-1: call void @cq_template_and_i32_hl_unc(
; UCNT-NOT: call void @cq_template_and_i32_hl_unc(

; ONE kickback gate in the rolled body.
; ACNT-COUNT-1: call void @cqrt_rz_i1(
; ACNT-NOT: call void @cqrt_rz_i1(

; THREE frees: the round-1 6.5 compare flag, then the body's bit rail and its
; flag, and NOTHING else. An extra `cqrt_free` is a hidden measurement (Rule 6).
; (The `%out` rail is the measure's and the two `%selop` copy sources are left
; allocated — Rule 6 leaks, never freed dirty.)
; FCNT-COUNT-3: call void @cqrt_free(
; FCNT-NOT: call void @cqrt_free(

; The `cqrt_x` census: 2 for the 6.5 arm's polarity bracket, 2 for the kickback's
; ¬flag bracket. An UNPAIRED one is a wrong-branch phase.
; XCNT-COUNT-4: call void @cqrt_x(i32
; XCNT-NOT: call void @cqrt_x(i32

; bd 3qlq, the FOURTH C-1 round, lens finding F-C1D-4: the Ry budget.
; NOTHING may add an uncontrolled `cqrt_ry` on a register under quantum
; control — a non-diagonal gate there is a different unitary, and before this
; prefix an injected one was caught by 0 of this file's prefixes.
; RYCNT-COUNT-1: call void @cqrt_ry_
; RYCNT-NOT: call void @cqrt_ry_

; WHOLE-FILE PURE-NEGATIVE.
; NOROUTE-NOT: @cqrt_cswap
; NOROUTE-NOT: @cq_phi
; NOROUTE-NOT: @cq_theta
; NOROUTE-NOT: call void @cqrt_rz_{{(i8|i16|i32|i64|f16|f32|f64|f80)}}(
; NOROUTE-NOT: @cqrt_rz_{{[a-z0-9]+}}_controlled(
; NOROUTE-NOT: fneg
; NOROUTE-NOT: call void @cqrt_rz_i1(i32 %{{.*}}, double -

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @slice() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 3, double noundef 5.000000e-01) #3
  %2 = icmp sgt i32 %1, 5
  br i1 %2, label %3, label %5

3:                                                ; preds = %0
  %4 = tail call i32 @ext_f(i32 noundef 7) #3
  br label %5

5:                                                ; preds = %3, %0
  %6 = phi i32 [ %4, %3 ], [ 5, %0 ]
  br label %9

7:                                                ; preds = %15
  %8 = tail call i32 @cq_measure_si32(i32 noundef %6) #3
  ret i32 %8

9:                                                ; preds = %15, %5
  %10 = phi i32 [ 0, %5 ], [ %16, %15 ]
  %11 = shl nuw nsw i32 1, %10
  %12 = and i32 %11, %6
  %13 = icmp eq i32 %12, 0
  br i1 %13, label %15, label %14

14:                                               ; preds = %9
  tail call void @cq_phi(double noundef 2.500000e-01) #3
  br label %15

15:                                               ; preds = %14, %9
  %16 = add nuw nsw i32 %10, 1
  %17 = icmp eq i32 %16, 3
  br i1 %17, label %7, label %9, !llvm.loop !6
}

define range(i32 -2147483548, -2147483648) i32 @ext_f(i32 noundef %0) local_unnamed_addr #2 {
  %2 = add nsw i32 %0, 100
  ret i32 %2
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1
declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1
declare void @cq_phi(double noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable }
attributes #1 = { nounwind }
attributes #2 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable }
attributes #3 = { nounwind }

!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
