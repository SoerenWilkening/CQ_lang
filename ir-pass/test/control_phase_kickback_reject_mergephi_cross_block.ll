; control_phase_kickback_reject_mergephi_cross_block.ll — **NOW AN ACCEPT**
; (bd `test_C_libtooling-hn29` / `-leyd` / `-52og`, Track P′, 2026-09-15).
;
; ⚠ THE `reject_` IN THE NAME IS HISTORY AND THE FILE IS DELIBERATELY NOT RENAMED.
; This is bd `test_C_libtooling-gahu`'s standing precedent, for the reason recorded
; there and in CLAUDE.md L8: a `git mv` can be RESURRECTED by a merge, leaving one
; module under two names with contradictory verdicts and no gate able to see it.
; The name is wrong; a rename is a separate, deliberate act. Add this file to
; `gahu`'s list rather than moving it.
;
; ⚠ THIS FILE'S OWN RETIREMENT TRIGGER FIRED, IN THE WORDS IT WAS WRITTEN IN. The
; previous header said: *"RETIREMENT TRIGGER: they become accepts when the
; positional prong is given a real CFG-bounded scan (all blocks on paths from the
; φ's block to `Pred`, visited-set bounded) instead of the single-block window it
; has today. That is a new walk and needs its own Rule-12 probe family and Rule-13
; round; it is NOT to be bought by simply deleting this fence."* That walk is
; `chainedThetaBetweenDefAndBranch` (`ArmClassify.cpp`); the fence was NOT deleted,
; and the three files that prove it are named below. CLAUDE.md L8 asked for this
; outcome to be RE-DERIVED rather than assumed, and it was: the shapes were
; measured declining on the ORACLE and on Track F′'s binary first.
;
; THE SHAPE: the phase consumer's `br` is NOT in the prep's merge block — an empty
; `gap` block sits between them — so the kickback's `Pred` is not the prep's
; `MergeBB`. Nothing separates it from the shipped in-`Pred` accept
; `control_phase_kickback_mergephi_rail.ll` except that one block.
;
; ⚠ AND THE STREAM PROVES IT: the gates below are `…_mergephi_rail.ll`'s, gate for
; gate and operand for operand (alloc, ry, alloc, ry_controlled, the branch-phase
; `cqrt_rz_i1`, the measure). THE WIDENING ADDS AN ACCEPT, NOT A STREAM. `h1` is
; read ONLY as the diagonal gate's target and is left ALLOCATED (Rule 6 —
; `Ry(θ)|0⟩ ≠ |0⟩`, never freed dirty); NOTHING is minted, stripped or freed,
; because for a φ the register IS the flag (Rule 7's kickback); no `cqrt_x` ever
; touches a user register.
;
; ⚠ THE OTHER HALF OF THE FIX IS AN EMISSION ORDER, AND THIS FILE IS WHY.
; The previous header was RIGHT where bd `hn29` was wrong. `hn29` records that
; *"the Kahn chain already schedules every kickback before every prep, so the
; emission order would be right"*; this header answered *"Break the adjacency and
; that edge does not fire: nothing then orders the two"* — and the MEASUREMENT is
; the header's. With the positional prong widened and nothing else, this module
; moved from one decline string to another (`control flow`, from
; `emitPhaseKickbackRegion`'s `CondV != R.Condition` identity check, after the
; prep's M-β had RAUW'd the branch operand and `flattenRegion` had freed the φ).
; What makes it lower is `classifyPhaseKickback` recording the prep's index in
; `Region.PrepRegionIdxs` for a CROSS-BLOCK φ leaf only, and the `PhaseKickback`
; edge loop in `SwapRouteEmit::lowerControlRegions` turning it into
; `Precedes[kickback] = {prep}` — the same direction the `hcrg` adjacency alias
; supplies for free when the φ IS in `Pred`. CLAUDE.md L6 in the other direction:
; the thing being protected really was the emitter's bookkeeping, and the way to
; fix bookkeeping is to fix the bookkeeping, not to delete the fence.
;
; THE FENCE IS STILL THERE AND STILL BITES — three files, each a decline:
;   `…_cross_block_theta.ll`         a chained Ry on the φ's own wire in `gap`;
;   `…_cross_block_offwire_theta.ll` a chained Ry on ANOTHER wire in `gap` — the
;                                    one no wire walk can see, so it is the file
;                                    that proves the POSITIONAL prong survived;
;   `…_inloop_latch_theta.ll`        a chained Ry after the branch inside a loop,
;                                    reached only across the back edge.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MDCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MDTAG < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MINT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=PHI < %t.cqd0.ll

declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i1 @example(i1 %u0) {
entry:
  %b0 = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  br i1 %b0, label %arm, label %merge
arm:
  %t = call i1 @cq_theta_i1(i1 false, double 2.500000e-01)
  br label %merge
merge:
  %b1 = phi i1 [ %t, %arm ], [ false, %entry ]
  br label %gap
gap:
  br i1 %b1, label %ph, label %done
ph:
  call void @cq_phi(double 9.000000e-01)
  br label %done
done:
  %m = call i1 @cq_measure_i1(i1 %b1)
  ret i1 %m
}

; CHECK:      %[[H0:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 %u0)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H0]], double 5.000000e-01)
; CHECK-NEXT: %[[H1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[H0]], i32 %[[H1]], double 2.500000e-01)
; CHECK:      call void @cqrt_rz_i1(i32 %[[H1]], double 9.000000e-01), !cq.branchphase
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H1]])

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
; PHI-NOT: = phi
