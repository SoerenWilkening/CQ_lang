; control_phase_kickback_mergephi_inloop_outside_prep.ll — ACCEPT
; (bd `test_C_libtooling-52og`, Track P′). THE ROLLED PHASE KICKBACK ON A
; BOOL-CONTROLLED PREP — the shape a rolled Grover phase kickback takes.
;
; ⚠ THE ASYMMETRY THIS FILE CLOSES, AND IT IS THE ONE CLAUDE.md §5 NAMES. The
; SELECT twin of this program — `control_swap_accept_select_mergephi_inloop_outside_prep.ll`,
; the same prep φ read from inside the same loop — has been a SHIPPED ACCEPT since
; bd `boi6`/Track M. The KICKBACK twin declined. Two CONSUMERS of ONE leaf grammar
; disagreeing about one program is not a safety margin; under the owner's
; 2026-09-11 ruling it is a defect, and this is its removal.
;
; THE SHAPE: `bool b0 = cq_theta(0,.5); bool b1 = 0; if (b0) b1 = cq_theta(b1,.5);
; for (i<3) { if (b1) cq_phi(.3); }` — the PREP outside the loop, the KICKBACK
; inside it. The prep's merge φ lives in the preheader-side block, the kickback's
; `Pred` is the loop HEADER, so the φ is cross-block and `condWireDisposition`'s
; P4 prong used to refuse it outright. It now takes
; `chainedThetaBetweenDefAndBranch`, which walks `merge`'s tail, the header up to
; its terminator, and then the header's successors ON THE BACK EDGE — finding
; nothing here, and finding the theta in `…_inloop_latch_theta.ll`.
;
; ROLLED, AND MEASURED SO — not inferred from the source. The `cqrt_rz_i1` below
; sits INSIDE `header`, so the emitted IR is independent of the trip count: the
; plain-C form of this program lowers to **44 lines at K=3 and 44 lines at
; K=1000** (measured without `-g`), and its runtime trace is **BYTE-IDENTICAL** to
; the hand-unrolled three-`cq_phi` twin's (`diff` empty). Three `cqrt_rz_i1(h1,.3)`
; lines at run time; one `cqrt_rz_i1` in the module.
;
; THE UNITARY. `cqrt_rz_i1` is DIAGONAL in `b1`'s basis, so K activations multiply
; the `|b1 = 1⟩` component by `e^{iKφ}` — exactly `for (i<K) if (b1) cq_phi(φ)`.
; NOTHING is minted, stripped or freed: for a φ the register IS the flag (Rule 7).
; `h1` is left ALLOCATED (Rule 6 — `Ry(θ)|0⟩ ≠ |0⟩`) and `h0` is read only as the
; prep's control. No `cqrt_x` anywhere.
;
; ⚠ WHAT MAKES THE ORDER RIGHT HERE IS THE NEW EDGE, NOT THE hcrg CHAIN. The
; kickback's `Pred` is the loop header and the prep's `MergeBB` is the preheader
; side, so `A.Pred == B.MergeBB` is FALSE and the sanctioned alias edge never
; fires. Plan (detection) order would emit the PREP first, M-β would RAUW the
; branch operand and `flattenRegion` would free the φ, and
; `emitPhaseKickbackRegion`'s identity check would decline `control flow`. The
; `Region.PrepRegionIdxs` record plus the `PhaseKickback` edge loop in
; `SwapRouteEmit::lowerControlRegions` is what schedules the kickback first.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ROLLED < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MDCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MDTAG < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MINT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=PHICNT < %t.cqd0.ll

declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)

define i1 @example(i1 %u0) {
entry:
  %b0 = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  br i1 %b0, label %arm, label %merge
arm:
  %t = call i1 @cq_theta_i1(i1 false, double 2.500000e-01)
  br label %merge
merge:
  %b1 = phi i1 [ %t, %arm ], [ false, %entry ]
  br label %header
header:
  %i = phi i32 [ 0, %merge ], [ %inext, %latch ]
  br i1 %b1, label %ph, label %latch
ph:
  call void @cq_phi(double 9.000000e-01)
  br label %latch
latch:
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %inext, 3
  br i1 %done, label %exit, label %header
exit:
  %m = call i1 @cq_measure_i1(i1 %b1)
  ret i1 %m
}

; CHECK:      %[[H0:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 %u0)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H0]], double 5.000000e-01)
; CHECK-NEXT: %[[H1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[H0]], i32 %[[H1]], double 2.500000e-01)
; CHECK:      call void @cqrt_rz_i1(i32 %[[H1]], double 9.000000e-01), !cq.branchphase
; CHECK:      %[[M:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H1]])

; ---- The "rolled" prefix below. The gate is INSIDE the loop, i.e. the back edge
; is still there and the induction phi still feeds it. Its own prefix, positives only.
; ROLLED: %{{.*}} = phi i32 [ 0, %{{.*}} ], [ %{{.*}}, %{{.*}} ]
; ROLLED: call void @cqrt_rz_i1(
; ROLLED: br i1 %{{.*}}, label %{{.*}}, label %{{.*}}

; ---- Whole-file negatives, each in its OWN pure prefix (a positive line inside
; a negative prefix WINDOWS every negative after it — CLAUDE.md Rule 12(a)).
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: cqrt_copy
; NOROUTE-NOT: cqrt_cnot
; NOROUTE-NOT: cqrt_toffoli
; NOROUTE-NOT: call void @cqrt_rz_{{(i8|i16|i32|i64|f16|f32|f64|f80)}}(
; NOROUTE-NOT: call void @cq_phi(
; NOROUTE-NOT: cq_phi_
; NOROUTE-NOT: call i1 @cq_theta_i1(
; XCNT-NOT: call void @cqrt_x(
; FCNT-NOT: call void @cqrt_free(
; MDCNT-COUNT-1: call void @cqrt_rz_i1(
; MDCNT-NOT: call void @cqrt_rz_i1(
; MDTAG-COUNT-1: call void @cqrt_rz_i1({{.*}}), !cq.branchphase
; MDTAG-NOT: call void @cqrt_rz_i1(
; ACNT-COUNT-2: call i32 @cqrt_alloc_
; ACNT-NOT: call i32 @cqrt_alloc_
; MINT-NOT: cq_template_
; MINT-NOT: _unc(
; ---- Exactly ONE phi survives — the loop's induction variable — and no other.
; This file cannot carry the family's `PHI-NOT: = phi` (a ROLLED loop must keep its
; induction phi), so the property is pinned as a COUNT in its own prefix instead.
; It was added because the injection matrix reported `MISSED M15 a phi appears`:
; without it an injected phi was invisible to all ten prefixes. Rule 12(c) — a
; fixture is validated by MUTATION, and the mutation is what found the gap.
; PHICNT-COUNT-1: = phi
; PHICNT-NOT: = phi
