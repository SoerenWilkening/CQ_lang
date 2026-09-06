; control_phase_kickback_mixed_merge_out_rail_preadd_inloop.ll — ACCEPT.
; bd test_C_libtooling-3qlq Inc 1, the FOURTH C-1 round (bd 7yd0 / OQ-C2-1 /
; review_inc2_r2 finding **F-I2-1**). THE PRODUCT OF TWO AXES THE TREE ALREADY
; HAD SEPARATELY AND NEVER TOGETHER.
;
;     int q=3,p=7,r=9; q=cq_theta(q,.5); p=cq_theta(p,.25); r=cq_theta(r,.3);
;     int m = (q > 5) ? p : r;             // 4.4 SELECT merge  ->  %out rail
;     m = m + 7;                           // PREHEADER dtzb op ON that rail
;     for (int i = 0; i < 4; ++i)
;         if (((m >> i) & 1)) cq_phi(0.7); // D4's per-bit idiom, ROLLED
;     return cq_measure(m);
;
; `clang -O1` output verbatim (`@main` dropped). Thirteen lines of plain C with
; no Inc-2 feature in them.
;
; WHAT WENT WRONG, AND WHY NOTHING SAW IT. Six
; `control_phase_kickback_mixed_preheader_*.ll` fixtures pin the PREHEADER
; in-place axis (all on a `cq_theta` ROOT MINT);
; `control_phase_kickback_inloop_merge_rail.ll` pins the MERGE-OUT-RAIL axis
; (with NO preheader op); the loop-twin matrix's sub-grid F3 has two cells, both
; theta roots. The PRODUCT existed in no fixture and no cell, and it LEAKED:
; MEASURED on `main` a3c1513, rolled **4 `cq_template_and_i32_hl` mints / 0
; `_hl_unc`** (44 trace lines) against a hand-unrolled twin of the same source at
; **4/4** (52 lines), and at K=32 **32 mints / 0** — an O(K) leak of entangled
; which-path records of the merged register's bits, `opt` exit 0, verify-clean,
; and STRICT stage 2b `0 violation(s)` (a template-minted rail has no
; `cqrt_alloc` to count, so 2b is structurally blind to the whole class).
;
; THE CAUSE was `commitOutOfLoopInPlaceOps`' stability conjunct `P->hasOneUse()`.
; A merge out-rail STRUCTURALLY cannot have one use: the Phase-4 emitters WRITE
; it before anything reads it (two `cqrt_copy_i32_controlled` here). `hasOneUse`
; cannot tell a PRIOR WRITER from a LATER READER; `classifyInPlaceReassignment`'s
; own G6/G7 pair can, and does. The conjunct is RETIRED — see that function's
; header — and the safety is the (1b) `PreLoopCommittedInPlaceOps` tripwire,
; which re-asks the same fence at `lowerOps` under the final DT/LI and taint and
; declines LOUDLY on a changed answer
; (`control_phase_kickback_reject_preloop_commit_stale.ll`).
;
; THE TWO BOUNDARY CONTROLS, both green on BOTH binaries, are what make this the
; PRODUCT and not either axis alone:
;   * `control_phase_kickback_inloop_merge_rail.ll` — merge out-rail, NO
;     preheader op (clause (ii-b) alone already served it);
;   * `control_phase_kickback_mixed_preheader_addc_inloop.ll` — theta root, WITH
;     a preheader op (the round-2 commit alone already served it).
; And `control_phase_kickback_mixed_preheader_add_outofplace_leak_control.ll`
; stays ACCEPT-AND-LEAKS: there M-C ITSELF goes out of place (a later read of the
; pre-op value), so the fence refuses and this file's widening cannot reach it.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=UCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=PCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MDCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RYCNT < %t.cqd0.ll

; The 4.4 select merge lowers first and mints `%out`; then the PREHEADER `+7`
; lands IN PLACE on that rail.
; CHECK: %[[OUT:.*]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK: call void @cqrt_copy_i32_controlled(i32 %{{.*}}, i32 %{{.*}}, i32 %[[OUT]])
; CHECK: call void @cqrt_copy_i32_controlled(i32 %{{.*}}, i32 %{{.*}}, i32 %[[OUT]])
; CHECK: call void @cq_template_icmp_sgt_i32_hl_unc(
; CHECK: call void @cqrt_free(
; CHECK: call void @cqrt_addc_i32(i32 %[[OUT]], i32 7)

; The ROLLED body, in order, with the per-iteration discharge that was missing.
; CHECK: %[[A:.*]] = call i32 @cq_template_and_i32_hl(i32 %[[OUT]], i32 %{{.*}})
; CHECK-NEXT: %[[F:.*]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[A]], i32 0)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F]], double 0x3FE6666666666666), !cq.branchphase
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[A]], i32 0)
; CHECK-NEXT: call void @cq_template_and_i32_hl_unc(i32 %[[A]], i32 %[[OUT]], i32 %{{.*}})
; CHECK-NEXT: call void @cqrt_free(i32 %[[A]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])

; ⭐ THE ASSERTION. ZERO on `main` a3c1513; every other positive directive above
; passed there. ONE in the ROLLED module, FOUR in the trace (K=4).
; UCNT-COUNT-1: call void @cq_template_and_i32_hl_unc(
; UCNT-NOT: call void @cq_template_and_i32_hl_unc(

; ⭐ THE OTHER HALF OF THE SUBJECT, IN ITS OWN PREFIX: the preheader op really is
; converted IN PLACE on the merge out-rail (this is what makes the leak a leak
; rather than an out-of-place fallback — the body reads the SAME physical wire).
; It is ONE gate against a K-times body; an adjoint of it would be the
; multiplicity hazard `markIfRailLocal`'s comment names, and there is none.
; PCNT-COUNT-1: call void @cqrt_addc_i32(
; PCNT-NOT: call void @cqrt_addc_i32(
; PCNT-NOT: @cqrt_addc_{{[a-z0-9]+}}_inv(
; PCNT-NOT: @cq_template_add_i32_hl(

; ACNT-COUNT-1: call void @cqrt_rz_i1(
; ACNT-NOT: call void @cqrt_rz_i1(

; Three frees: the 4.4 compare flag, then the body's bit rail + flag. The bit
; rail's free is the second half of the fix (`main` emits two). An EXTRA
; `cqrt_free` is a hidden measurement (Rule 6).
; FCNT-COUNT-3: call void @cqrt_free(
; FCNT-NOT: call void @cqrt_free(

; Four `cqrt_x`: the 4.4 merge's two polarity brackets and the kickback's ¬flag
; bracket (two). An UNPAIRED one is a wrong-branch phase.
; XCNT-COUNT-4: call void @cqrt_x(i32
; XCNT-NOT: call void @cqrt_x(i32

; The kickback gate is recorded, so the spine cannot adjoint the user's phase.
; MDCNT-COUNT-1: !cq.branchphase
; MDCNT-NOT: !cq.branchphase

; bd 3qlq, the FOURTH C-1 round, lens finding F-C1D-4: the Ry budget.
; NOTHING may add an uncontrolled `cqrt_ry` on a register under quantum
; control — a non-diagonal gate there is a different unitary, and before this
; prefix an injected one was caught by 0 of this file's prefixes.
; RYCNT-COUNT-3: call void @cqrt_ry_
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
  %1 = tail call i32 @cq_theta_si32(i32 noundef 3, double noundef 5.000000e-01) #2
  %2 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 2.500000e-01) #2
  %3 = tail call i32 @cq_theta_si32(i32 noundef 9, double noundef 3.000000e-01) #2
  %4 = icmp sgt i32 %1, 5
  %5 = select i1 %4, i32 %2, i32 %3
  %6 = add nsw i32 %5, 7
  br label %9

7:                                                ; preds = %15
  %8 = tail call i32 @cq_measure_si32(i32 noundef %6) #2
  ret i32 %8

9:                                                ; preds = %0, %15
  %10 = phi i32 [ 0, %0 ], [ %16, %15 ]
  %11 = shl nuw nsw i32 1, %10
  %12 = and i32 %11, %6
  %13 = icmp eq i32 %12, 0
  br i1 %13, label %15, label %14

14:                                               ; preds = %9
  tail call void @cq_phi(double noundef 0x3FE6666666666666) #2
  br label %15

15:                                               ; preds = %9, %14
  %16 = add nuw nsw i32 %10, 1
  %17 = icmp eq i32 %16, 4
  br i1 %17, label %7, label %9, !llvm.loop !6
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1
declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1
declare void @cq_phi(double noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable }
attributes #1 = { nounwind }
attributes #2 = { nounwind }

!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
