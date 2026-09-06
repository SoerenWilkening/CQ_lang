; control_phase_kickback_mixed_value_merge_dtzb_head_preadd_inloop.ll — ACCEPT.
; bd test_C_libtooling-3qlq, the FOURTH C-1 round (bd 7yd0) rebased onto the
; landed Increment 2, item **F-C1E-1** of the lens on that rebased tree
; (`review_c1e`, verdict CLEAR-WITH-ITEMS).
;
; WHY THIS FILE EXISTS — and read it beside its sibling
; `control_phase_kickback_mixed_value_merge_preadd_inloop.ll`, because the two
; pin DIFFERENT things and the sibling was cited for a third. That sibling is
; the `q4b` shape (`p=p+3; p=p*5; …`), and `clang -O1` REASSOCIATES `(p+3)*5`
; into `p*5 + 15`, so in ITS module `p`'s only chain user is a `mul`. M-C's
; `inPlaceValueRailOperand` admits `add`/`xor` ONLY, so there G2's SHAPE half
; refuses the head whatever `classifyInPlaceReassignment`'s G6/G7 pair answers,
; and its `HCNT-NOT` lines survive a relaxation of that pair. MEASURED by the
; lens on a binary it built with BOTH G6 and G7 made unreachable
; (`review_c1e` F-C1E-1, `$W/mut_g67`): the sibling fixture stays GREEN there and
; the emitted copies are byte-unchanged. THIS module's chain head IS a dtzb-shaped
; `add` (`p + 3`), so nothing but G6/G7 stands between it and an in-place
; `cqrt_addc_i32` on `p`'s own rail — and on that same mutant this program's two
; `cqrt_copy_i32_controlled` COLLAPSE ONTO ONE REGISTER, the CONSUMER-2
; miscompile `ArithLowering.cpp` describes. (The mutant is the lens's
; measurement, not a fixture: nothing in-tree rebuilds it. The property this
; file pins is the one that mutant breaks — the head OUT of place and the two
; copy sources DISTINCT. The G6/G7 net itself is pinned in-tree by
; `control_swap_value_ifelse_head_out_of_place.ll`, which goes RED on it.)
;
;     int q=3,p=7; q=cq_theta(q,.5); p=cq_theta(p,.25);
;     int r = p;
;     if (q>3){ r = p + 3; r = r ^ 9; }   // dtzb-shaped chain HEAD on `p`
;     r = r + 7;                          // PREHEADER dtzb op on the merge rail
;     for (int i = 0; i < 4; ++i)
;         if (((r >> i) & 1)) cq_phi(0.7); // D4's per-bit idiom, ROLLED
;     return cq_measure(r);
;
; `clang -O1` output of `review_c1e`'s attack program `a22` verbatim (`@main`
; dropped). ⚠ `-O1` FOLDS that diamond into a `select`, so the merge is the 4.4
; `SelectMergeEmit` — the SAME controlled-copy merge Inc 2's `emitValueRegion`
; delegates to (Rule 14), which is why the emitted shape is the sibling's.
;
; RED/GREEN, MEASURED on this module (not inferred), `cq-opt` exit 0 on both:
;   * `main` 258d974: `cq_template_and_i32_hl_unc` **0**, `cqrt_free` **2** — the
;     per-activation bit rail LEAKS, one per trip, verify-clean and STRICT
;     stage 2b `0 violation(s)` (a template-minted rail has no `cqrt_alloc` to
;     count). Prefixes RED there: CHECK, UCNT, FCNT.
;   * this tree: `..._unc` **1**, `cqrt_free` **3**. The lens measured the same
;     source rolled == hand-unrolled BYTE-IDENTICAL here and DIVERGENT on `main`.
;
; The chain-final rail (`%h_op`, after its in-place `^9`) is LEFT ALLOCATED and
; entangled on purpose — PRD §0 E1 — which is why `cqrt_free` is 3, not 4.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=UCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=HCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CSRC < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=PCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=QCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RYCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MDCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll

; The whole prologue as a `-NEXT` chain, so nothing can be inserted into it
; (this is what makes the windowed `HCNT-NOT`s below sufficient: the only region
; the NOT window does not cover is pinned here, instruction for instruction).
; CHECK: %[[Q:.*]] = call i32 @cqrt_alloc_i32(i32 3)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK-NEXT: %[[P:.*]] = call i32 @cqrt_alloc_i32(i32 7)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[P]], double 2.500000e-01)
; CHECK-NEXT: %[[HEAD:.*]] = call i32 @cq_template_add_i32_hl(i32 %[[P]], i32 3)
; CHECK-NEXT: call void @cqrt_xorc_i32(i32 %[[HEAD]], i32 9)
; CHECK-NEXT: %[[CF:.*]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 3)
; CHECK-NEXT: %[[OUT:.*]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[CF]], i32 %[[HEAD]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[CF]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[CF]], i32 %[[P]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[CF]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[CF]], i32 %[[Q]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[CF]])

; ⭐ THE PREHEADER `+7` LANDS IN PLACE ON THAT MERGE OUT-RAIL — the round-4
; capability. The loop body then reads the SAME physical wire, which is what
; makes the missing discharge below a which-path leak rather than a spare rail.
; CHECK-NEXT: call void @cqrt_addc_i32(i32 %[[OUT]], i32 7)

; The ROLLED body, in order, with the per-iteration discharge `main` omits.
; CHECK: %[[A:.*]] = call i32 @cq_template_and_i32_hl(i32 %[[OUT]], i32 %{{.*}})
; CHECK-NEXT: %[[F:.*]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[A]], i32 0)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F]], double 0x3FE6666666666666), !cq.branchphase
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[A]], i32 0)
; CHECK-NEXT: call void @cq_template_and_i32_hl_unc(i32 %[[A]], i32 %[[OUT]], i32 %{{.*}})
; CHECK-NEXT: call void @cqrt_free(i32 %[[A]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])

; ⭐ THE FIX. ZERO on `main` 258d974; ONE in the ROLLED module, FOUR in the
; trace (K=4).
; UCNT-COUNT-1: call void @cq_template_and_i32_hl_unc(
; UCNT-NOT: call void @cq_template_and_i32_hl_unc(

; ⭐ THE DISCRIMINATOR, HALF 1 — the dtzb-shaped chain HEAD is emitted OUT of
; place onto a FRESH rail, and `p`'s own rail carries NO in-place `cqrt_addc` /
; `cqrt_xorc` from there to the end of the module. G6/G7 refuse M-C on the head
; because `%[[P2]]` is read again by the ¬flag arm of the merge. Unlike the
; sibling's `mul`, an `add` is inside `inPlaceValueRailOperand`'s shape, so this
; block is falsifiable by relaxing that pair alone.
; HCNT: %[[P2:.*]] = call i32 @cqrt_alloc_i32(i32 7)
; HCNT-NEXT: call void @cqrt_ry_i32(i32 %[[P2]], double 2.500000e-01)
; HCNT-NEXT: %{{.*}} = call i32 @cq_template_add_i32_hl(i32 %[[P2]], i32 3)
; HCNT-NOT: call void @cqrt_addc_i32(i32 %[[P2]],
; HCNT-NOT: call void @cqrt_xorc_i32(i32 %[[P2]],

; ⭐ THE DISCRIMINATOR, HALF 2 — the two controlled copies write ONE out-rail
; under ONE flag and read DISTINCT registers: the chain result `%[[HD]]` and the
; untouched source `%[[PS]]`. On the lens's G6/G7-disabled mutant both collapse
; onto `%[[PS]]` (`out = f ? R(p) : R(p)` — the arm silently lost, invisible to
; `opt -verify`, to the golden byte-diff and to `free_pairing_check.py`).
; CSRC: %[[PS:.*]] = call i32 @cqrt_alloc_i32(i32 7)
; CSRC: %[[HD:.*]] = call i32 @cq_template_add_i32_hl(i32 %[[PS]], i32 3)
; CSRC: call void @cqrt_copy_i32_controlled(i32 %[[CF2:.*]], i32 %[[HD]], i32 %[[O:.*]])
; CSRC-NEXT: call void @cqrt_x(i32 %[[CF2]])
; CSRC-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[CF2]], i32 %[[PS]], i32 %[[O]])

; The module's in-place `add` budget is exactly ONE: the preheader op on the
; merge out-rail. A SECOND would be a further mutation of a quantum register.
; PCNT-COUNT-1: call void @cqrt_addc_i32(
; PCNT-NOT: call void @cqrt_addc_i32(
; PCNT-NOT: @cqrt_addc_{{[a-z0-9]+}}_inv(

; The in-place `xor` budget is exactly ONE: the chain's `^9`, on the chain's own
; FRESH rail, never on `p`'s. It gets its own prefix rather than joining PCNT
; because a positive COUNT after a NOT WINDOWS that NOT (the Inc-3/Inc-4
; recurrence), and the `xorc` precedes the `addc` in this module.
; QCNT-COUNT-1: call void @cqrt_xorc_i32(
; QCNT-NOT: call void @cqrt_xorc_i32(
; QCNT-NOT: @cqrt_xorc_{{[a-z0-9]+}}_inv(

; ACNT-COUNT-1: call void @cqrt_rz_i1(
; ACNT-NOT: call void @cqrt_rz_i1(

; Three frees: the merge's compare flag, then the body's bit rail + flag. The
; bit rail's free is the fix (`main` emits 2). The chain FINAL is deliberately
; NOT freed (PRD §0 E1). An EXTRA `cqrt_free` is a hidden measurement (Rule 6).
; FCNT-COUNT-3: call void @cqrt_free(
; FCNT-NOT: call void @cqrt_free(

; Four `cqrt_x`: the merge's polarity bracket (two) and the kickback's ¬flag
; bracket (two). An UNPAIRED one is a wrong-branch phase.
; XCNT-COUNT-4: call void @cqrt_x(i32
; XCNT-NOT: call void @cqrt_x(i32

; The Ry budget: two roots, two rotations, and NOTHING may add an uncontrolled
; `cqrt_ry` on the merged register (F-C1D-4).
; RYCNT-COUNT-2: call void @cqrt_ry_
; RYCNT-NOT: call void @cqrt_ry_

; The kickback gate is recorded, so the spine cannot adjoint the user's phase.
; MDCNT-COUNT-1: !cq.branchphase
; MDCNT-NOT: !cq.branchphase

; WHOLE-FILE PURE-NEGATIVE. `cqrt_cswap` is minted by `AbortParkEmit` alone
; since Inc 2 — a merge never routes.
; NOROUTE-NOT: @cqrt_cswap
; NOROUTE-NOT: @cq_phi
; NOROUTE-NOT: @cq_theta
; NOROUTE-NOT: call void @cqrt_rz_{{(i8|i16|i32|i64|f16|f32|f64|f80)}}(
; NOROUTE-NOT: @cqrt_rz_{{[a-z0-9]+}}_controlled(
; NOROUTE-NOT: fneg
; NOROUTE-NOT: call void @cqrt_rz_i1(i32 %{{.*}}, double -
; NOROUTE-NOT: call i32 @cq_template_mul_i32_hl(

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @slice() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 3, double noundef 5.000000e-01) #2
  %2 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 2.500000e-01) #2
  %3 = icmp sgt i32 %1, 3
  %4 = add nsw i32 %2, 3
  %5 = xor i32 %4, 9
  %6 = select i1 %3, i32 %5, i32 %2
  %7 = add nsw i32 %6, 7
  br label %10

8:                                                ; preds = %16
  %9 = tail call i32 @cq_measure_si32(i32 noundef %7) #2
  ret i32 %9

10:                                               ; preds = %0, %16
  %11 = phi i32 [ 0, %0 ], [ %17, %16 ]
  %12 = shl nuw nsw i32 1, %11
  %13 = and i32 %12, %7
  %14 = icmp eq i32 %13, 0
  br i1 %14, label %16, label %15

15:                                               ; preds = %10
  tail call void @cq_phi(double noundef 0x3FE6666666666666) #2
  br label %16

16:                                               ; preds = %10, %15
  %17 = add nuw nsw i32 %11, 1
  %18 = icmp eq i32 %17, 4
  br i1 %18, label %8, label %10, !llvm.loop !6
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
