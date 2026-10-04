; control_phase_kickback_share_flag.ll — ACCEPT. THE ziov SHARED-FLAG KICKBACK,
; and the pin for the Rule-13 ROUND-1 CONFIRMED SILENT MISCOMPILE F-L7-1 /
; F-L1-1 / F-L2-1 (three independent lenses, one defect; bd
; test_C_libtooling-3qlq Inc 1 part A).
;
;     int q = 3; cq_theta(&q, 0.5);
;     int f = (q > 5);              // the compare is ALSO read as DATA
;     if (q > 5) cq_phi(0.25);      // the kickback
;     return cq_measure(f);
;
; This is `clang -O1` output verbatim (`$SP/progress/review_r1_L1/probes/
; u9_share_measureflag.c`); the compare `%2` has TWO users — the branch and the
; `zext` — so `ArmClassify` sets `R.ShareCondFlag`, the flag is minted AT THE
; COMPARE, and `emitPhaseKickbackRegion` SKIPS the strip and the free because the
; data lineage owns the flag.
;
; WHAT WENT WRONG, AND WHY NO SHIPPED GATE SAW IT. With the flag handed to the
; data lineage, the Phase-5 whole-DAG uncompute spine treated it as an ordinary
; reclaimable rail. `ChainWalk::isInPlaceGateOn`'s uncontrolled-rotation row
; admits `cqrt_rz_<W>(H, θ)`, so the KICKBACK GATE joined `D.Calls` and
; `emitDagReversal` emitted its adjoint:
;
;     cq_template_icmp_sgt_i32_hl(h0, 5) -> h1
;     cqrt_rz_i1(h1, 0x1p-2)                <-- the user's phase
;     cq_template_zext_i1_to_i32(h1) -> h2
;     cqrt_rz_i1(h1, -0x1p-2)               <-- THE SPINE'S ADJOINT
;     cq_template_icmp_sgt_i32_hl_unc(h1, h0, 5)
;     cqrt_free(h1)
;
; Both gates are diagonal in the same basis label and the copy between them moves
; no label, so `P(θ)·P(−θ) = I` EXACTLY: the emitted circuit was byte-for-byte the
; circuit for the same program with the `cq_phi` DELETED. `opt` exit 0,
; verify-clean, STRICT stage-2b PASS (a dropped phase mints and frees nothing —
; the checker was arguably HAPPIER than on the correct circuit, because the
; spine's reversal is what made the free provable). PRD §1's own defect class
; re-entering through a different door.
;
; THE FIX IS MEMBERSHIP, NOT A NAME (`ChainWalk::markBranchPhaseGate` /
; `isBranchPhaseGate`): every emitted kickback gate carries `!cq.branchphase`, and
; `isInPlaceGateOn` / `preservesBasisUnderRecord` / `EmitInverse::
; isInverseEmittable` refuse a member outright. The gate becomes an UNRECOGNIZED
; consumer, so the DAG is `NotClosed` and the flag rail is LEFT ALLOCATED — Rule-6
; safe (a leak, never a dirty free) and BYTE-FOR-BYTE the pre-3qlq oracle's own
; disposition on this source (`cqrt_rz_i32_controlled(h1,h0,θ)` … `zext` …
; `measure`, with no strip and no free — MEASURED on $SP/wt/pre-3qlq).
;
; WHY THE NEGATIVE ASSERTION AND NOT A COUNT (lens L1's measurement): the broken
; module contains TWO `cqrt_rz_i1` calls, so a bare count-of-one directive stays GREEN on
; it. The discriminator has to name the NEGATED ANGLE. Both the count and the
; negative are therefore asserted, in SEPARATE prefixes — a positive COUNT inside
; a negative prefix windows every negative after it (the Inc-3 F-L6-1 / Inc-4 lesson).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RYCNT < %t.cqd0.ll

; The kickback gate lands on the FLAG, uncontrolled, and is recorded.
; CHECK: %[[F:.*]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %{{.*}}, i32 5)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F]], double 2.500000e-01), !cq.branchphase
; CHECK-NEXT: %[[Z:.*]] = call i32 @cq_template_zext_i1_to_i32(i32 %[[F]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[Z]])

; Exactly one phase gate.
; ACNT-COUNT-1: call void @cqrt_rz_i1(
; ACNT-NOT: call void @cqrt_rz_i1(

; The flag rail is LEFT ALLOCATED on this path — the data lineage owned it and the
; spine can no longer close it, which is the oracle's disposition. Zero frees.
; FCNT-NOT: call void @cqrt_free(

; bd 3qlq, the FOURTH C-1 round, lens finding F-C1D-4: the Ry budget.
; NOTHING may add an uncontrolled `cqrt_ry` on a register under quantum
; control — a non-diagonal gate there is a different unitary, and before this
; prefix an injected one was caught by 0 of this file's prefixes.
; RYCNT-COUNT-1: call void @cqrt_ry_
; RYCNT-NOT: call void @cqrt_ry_

; NOROUTE is WHOLE-FILE and PURE-NEGATIVE.
; NOROUTE-NOT: double -
; NOROUTE-NOT: fneg
; NOROUTE-NOT: @cqrt_cswap
; NOROUTE-NOT: _controlled
; NOROUTE-NOT: @cq_phi
; NOROUTE-NOT: _unc


; ── Rule-13 ROUND-2 finding F-R2-1, the assertion repair ────────────────────
; Round 1 repaired three assertion families (the 8-width Rz negative, the
; `cqrt_x` negative, the `cqrt_free` count) in the corpus IT could see, and the
; merge brought in a set that had never been asked the same question. Measured by
; injection at `c4bd888`: `cqrt_rz_f80`/`f16` NOT CAUGHT in 18 accepts, an
; UNPAIRED `cqrt_x` (a wrong-branch phase) NOT CAUGHT in 21, an EXTRA
; `cqrt_free` (a hidden measurement, Rule 6) NOT CAUGHT in 20. Every accept in
; the branch now carries all three, and each is validated by injecting the line
; into this fixture's OWN output.
; NOROUTE-NOT: call void @cqrt_rz_{{(i8|i16|i32|i64|f16|f32|f64|f80)}}(
; NOROUTE-NOT: call void @cqrt_x(i32


define i32 @slice() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 3, double noundef 5.000000e-01) #2
  %2 = icmp sgt i32 %1, 5
  br i1 %2, label %3, label %4

3:                                                ; preds = %0
  tail call void @cq_phi(double noundef 2.500000e-01) #2
  br label %4

4:                                                ; preds = %3, %0
  %5 = zext i1 %2 to i32
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5) #2
  ret i32 %6
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1
declare void @cq_phi(double noundef) local_unnamed_addr #1
declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable }
attributes #1 = { nounwind }
attributes #2 = { nounwind }
