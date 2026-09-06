; control_phase_kickback_mixed_value_merge_preadd_inloop.ll — ACCEPT.
; bd test_C_libtooling-3qlq, the FOURTH C-1 round (bd 7yd0) REBASED onto the
; landed Increment 2 (`main` 258d974). This is the fixture round 4 could only
; ARGUE: its own record's step 17 and its RECORD ITEM say the Inc-2 producer of
; the merge rail "CANNOT be measured until the orchestrator rebases this branch
; onto the landed Inc 2". This file is that measurement, pinned.
;
;     int q=3,p=7; q=cq_theta(q,.5); p=cq_theta(p,.25);
;     if (q>3){ p=p+3; p=p*5; p=p^9; p=p+1; p=p*7; p=p^2; }  // Inc-2 VALUE ARM
;     p = p + 7;                            // PREHEADER dtzb op on the %out rail
;     for (int i = 0; i < 4; ++i)
;         if (((p >> i) & 1)) cq_phi(0.7);  // D4's per-bit idiom, ROLLED
;     return cq_measure(p);
;
; `clang -O1` output of `inc1-records/c1-round4/q4b_preadd_rolled.c` verbatim
; (`@main` dropped). Since Inc 2 the arm lowers by the CONTROLLED-COPY MERGE:
; the pure chain is HOISTED to the pred and the answer merged into a fresh |0>
; rail by two X-bracketed `cqrt_copy_i32_controlled` — so `%out` has TWO WRITERS
; before any reader, which is exactly the shape `P->hasOneUse()` refused.
;
; RED/GREEN, MEASURED on this module (not inferred):
;   * `main` 258d974 (Inc 2 landed): `cq_template_and_i32_hl_unc` **0**,
;     `cqrt_free` **3** — the four per-activation bit rails LEAK, `opt` exit 0,
;     verify-clean, STRICT stage 2b `0 violation(s), 0 unproven`. The trace is
;     4 mints / 0 discharges at 52 lines against a hand-unrolled twin of the
;     same source at 4/4 / 60 (`cmp` DIVERGE 8).
;   * this tree: `..._unc` **1**, `cqrt_free` **4**, and the ROLLED trace is
;     BYTE-IDENTICAL to that hand-unrolled twin's (60 = 60), which is the
;     witness — `e2e-phase-perbit-loop-value-merge-preadd-twin-identical`.
; So round 4's fix serves the Inc-2 producer too, and the ANALYTIC row in
; `inc1-records/c1-round4/README.md` becomes a measured one.
;
; ⭐ F-C1D-2's PIN — "the commit cannot reach an Inc-2 chain HEAD". The lens
; asked for this and could not pin it: the head is a USER of the arm's input
; `%h2`, never an ancestor on the peel chain from a loop-invariant candidate,
; and a merge `%out`'s peel stops at its own `cqrt_alloc`. MEASURED here in the
; `HCNT` prefix: the head is `cq_template_mul_i32_hl(%h2, 5)` — OUT of place,
; onto a FRESH rail — and `p`'s own rail is NEVER mutated in place, because it
; is read by the ¬flag arm of the merge. That is `classifyInPlaceReassignment`'s
; G6/G7 pair (Inc 2's own "CONSUMER 2" comment in `ArithLowering.cpp`), the sole
; net there since this round retired `hasOneUse` from the COMMIT path.
; ⚠ `clang -O1` REASSOCIATES `(p+3)*5` to `p*5 + 15`, so the head is a `mul`
; and `cq_template_add_i32_hl` count is **0**, not the `add` one might expect.
;
; The chain FINAL rail `%h_op3` is LEFT ALLOCATED and entangled on purpose
; (PRD §0 E1) — that is why `cqrt_free` is 4 and not 5.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=UCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=HCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=PCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RYCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MDCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll

; The Inc-2 value arm: the pure chain HOISTED to the pred and run
; unconditionally on a FRESH rail, then merged into a |0> out-rail by two
; X-bracketed controlled copies, then the compare strip and ONE free.
; CHECK: %[[P:.*]] = call i32 @cqrt_alloc_i32(i32 7)
; CHECK: %[[HEAD:.*]] = call i32 @cq_template_mul_i32_hl(i32 %[[P]], i32 5)
; CHECK: %[[TAIL:.*]] = call i32 @cq_template_mul_i32_hl(i32 %[[HEAD]], i32 7)
; CHECK: call void @cq_template_mul_i32_hl_unc(i32 %[[HEAD]], i32 %[[P]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[HEAD]])
; CHECK: %[[CF:.*]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %{{.*}}, i32 3)
; CHECK-NEXT: %[[OUT:.*]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[CF]], i32 %[[TAIL]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[CF]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[CF]], i32 %[[P]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[CF]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[CF]], i32 %{{.*}}, i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[CF]])

; ⭐ THE PREHEADER `+7` LANDS IN PLACE ON THAT MERGE OUT-RAIL. This is what
; makes the leak a leak rather than an out-of-place fallback: the loop body
; reads the SAME physical wire.
; CHECK-NEXT: call void @cqrt_addc_i32(i32 %[[OUT]], i32 7)

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

; ⭐ THE ASSERTION. ZERO on `main` 258d974; every other positive directive above
; passes there. ONE in the ROLLED module, FOUR in the trace (K=4).
; UCNT-COUNT-1: call void @cq_template_and_i32_hl_unc(
; UCNT-NOT: call void @cq_template_and_i32_hl_unc(

; ⭐ F-C1D-2. The Inc-2 chain HEAD is OUT of place onto a fresh rail, and `p`'s
; own rail carries NO in-place dtzb op — G6/G7 refuse it because `%[[P2]]` is
; read later by the ¬flag arm of the merge. Delete that pair and this block
; goes red; the commit path alone cannot produce it.
; HCNT: %[[P2:.*]] = call i32 @cqrt_alloc_i32(i32 7)
; HCNT-NEXT: call void @cqrt_ry_i32(i32 %[[P2]], double 2.500000e-01)
; HCNT-NEXT: %{{.*}} = call i32 @cq_template_mul_i32_hl(i32 %[[P2]], i32 5)
; HCNT-NOT: call void @cqrt_addc_i32(i32 %[[P2]],
; HCNT-NOT: call void @cqrt_xorc_i32(i32 %[[P2]],

; The whole module's in-place `add` budget: THREE on the hoisted chain's own
; interior rails (`+15`, its `-15` adjoint, and the folded `+1` as `*7 + 7`) and
; ONE on the merge out-rail (the subject). A FIFTH would be an extra mutation of
; a quantum register; `cq_template_add_i32_hl` is 0 because `-O1` reassociated
; the chain head into the `mul`.
; PCNT-COUNT-4: call void @cqrt_addc_i32(
; PCNT-NOT: call void @cqrt_addc_i32(
; PCNT-NOT: @cqrt_addc_{{[a-z0-9]+}}_inv(
; PCNT-NOT: call i32 @cq_template_add_i32_hl(

; ACNT-COUNT-1: call void @cqrt_rz_i1(
; ACNT-NOT: call void @cqrt_rz_i1(

; Four frees: the hoisted chain's interior rail, the merge's compare flag, then
; the body's bit rail + flag. The bit rail's free is the fix (`main` emits 3).
; The chain FINAL is deliberately NOT freed (PRD §0 E1). An EXTRA `cqrt_free` is
; a hidden measurement (Rule 6).
; FCNT-COUNT-4: call void @cqrt_free(
; FCNT-NOT: call void @cqrt_free(

; Four `cqrt_x`: the merge's two polarity brackets and the kickback's ¬flag
; bracket (two). An UNPAIRED one is a wrong-branch phase.
; XCNT-COUNT-4: call void @cqrt_x(i32
; XCNT-NOT: call void @cqrt_x(i32

; ⭐ F-C1D-4: the Ry budget. Two roots, two rotations, and NOTHING may add an
; uncontrolled `cqrt_ry` on the merged register after the flag's free.
; RYCNT-COUNT-2: call void @cqrt_ry_
; RYCNT-NOT: call void @cqrt_ry_

; The kickback gate is recorded, so the spine cannot adjoint the user's phase.
; MDCNT-COUNT-1: !cq.branchphase
; MDCNT-NOT: !cq.branchphase

; WHOLE-FILE PURE-NEGATIVE. `cqrt_cswap` is minted by `AbortParkEmit` alone
; since Inc 2 — a value arm never routes.
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
  %3 = icmp sgt i32 %1, 3
  br i1 %3, label %4, label %11

4:                                                ; preds = %0
  %5 = mul i32 %2, 5
  %6 = add i32 %5, 15
  %7 = xor i32 %6, 9
  %8 = mul i32 %7, 7
  %9 = add i32 %8, 7
  %10 = xor i32 %9, 2
  br label %11

11:                                               ; preds = %4, %0
  %12 = phi i32 [ %10, %4 ], [ %2, %0 ]
  %13 = add nsw i32 %12, 7
  br label %16

14:                                               ; preds = %22
  %15 = tail call i32 @cq_measure_si32(i32 noundef %13) #2
  ret i32 %15

16:                                               ; preds = %11, %22
  %17 = phi i32 [ 0, %11 ], [ %23, %22 ]
  %18 = shl nuw nsw i32 1, %17
  %19 = and i32 %18, %13
  %20 = icmp eq i32 %19, 0
  br i1 %20, label %22, label %21

21:                                               ; preds = %16
  tail call void @cq_phi(double noundef 0x3FE6666666666666) #2
  br label %22

22:                                               ; preds = %16, %21
  %23 = add nuw nsw i32 %17, 1
  %24 = icmp eq i32 %23, 4
  br i1 %24, label %14, label %16, !llvm.loop !6
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
