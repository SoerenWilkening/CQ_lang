; control_inplace_ry_reject_stateprep_acyclic_nondominated_phi.ll — DECLINE (F2),
; and it is the tripwire for the **ACYCLIC HALF** of the 2026-09-14 dominance
; skip in `collectStatePrepPhiDescendants` (bd `test_C_libtooling-om35`, round-2
; Rule-13 review finding F-F2-2).
;
; ⚠ THIS FILE PINS AN **OVER-DECLINE**, DELIBERATELY. Read that before changing
; anything: the value the skip removes here WAS a licensed exclusion, so the
; decline below is a capability cost in the SAFE direction, not a correctness
; repair. It is committed because the predicate had customers nobody had named.
;
; THE MIS-SCOPED RATIONALE THIS FILE CORRECTS. The skip
; `if (isa<PHINode>(I) && !DT.dominates(MergeBB, I->getParent())) continue;` was
; written for a CYCLIC shape — a LOOP-HEADER phi that takes an `M`-descendant on
; its BACK EDGE and so dominates both of F2's slots while sitting in the user
; closure — and its retirement trigger named bd `test_C_libtooling-wx8g` (the
; in-loop state prep) as though the loop were the whole story. IT IS NOT. The
; test actually spelled is *"is this phi's block dominated by `MergeBB`?"*, and
; that is FALSE in a fully acyclic CFG whenever a classical branch BYPASSES the
; region and re-joins after it.
;
; WHAT THIS MODULE IS, AND IT CONTAINS NO LOOP ANYWHERE. `%g = icmp sgt i32
; %arg, 100` is an opaque classical guard that bypasses the state-prep diamond
; (`%entry -> %Y -> %J`). `%u` in the merge block `%mB` is an `%MB`-descendant
; folding to `{0}` == the seed. `%p = phi i32 [ %u, %mB ], [ 0, %Y ]` sits in
; `%J`, which `%mB` does NOT dominate — with no back edge, no latch, no cycle:
; `entry -> {pre, Y}; pre -> {armB, mB}; armB -> mB; mB -> J; Y -> J; J -> ret`.
;
; ⚠ RED-GREEN, AND THE RED HALF IS A BINARY. MEASURED on the three binaries of
; the increment:
;   * ORACLE (`cq-opt` sha256 f7b65d8c…, from 59ac5b7, no phi-descendant
;     exclusion at all): F2, the string below.
;   * UN-NARROWED subject (sha256 147cb3d6…, the conjunct WITHOUT the dominance
;     skip): `cq taint escape: tainted value muxed by a classical-condition phi`
;     — `%p` is EXCLUDED, F2 does not fire, and the module falls through to
;     `declineClassicalMuxes`. **A MOVER, on a module with no loop.**
;   * NARROWED subject (sha256 96fdd3a9…): F2 again, the string below.
; Both binaries decline at the top level; only the STRING moves. That is why the
; over-decline is a cost that is not yet observable as a lost ACCEPT anywhere —
; every acyclic non-dominated-phi spelling constructed so far is masked by
; `declineClassicalMuxes`. A FAILED CONSTRUCTION IS NOT A PROOF THAT NONE EXISTS.
;
; ⚠ RETIREMENT TRIGGER (L8), AND IT IS **NOT** `wx8g`. `wx8g` is the trigger for
; the CYCLIC half only (see the back-edge fixture PAIR
; `control_inplace_ry_reject_stateprep_backedge_{phidesc,nonphidesc}_collider.ll`).
; The trigger for THIS half is the precise predicate: the question the
; availability ground needs is *"is this phi AVAILABLE at a slot?"* — test the
; MEMBER against the SLOTS (`isa<PHINode>(I) && DT.dominates(I, BI)`, plus a
; second clause for the ARM slot, since a phi at the top of the arm block taking
; `M` on a back edge is available at the arm and not at the pred) — rather than
; against `MergeBB`. That is a Rule-13 CORE predicate change on the function that
; lost four consecutive rounds in drbq Inc 4, so it is FILED FOR AN OWNER
; DECISION as **bd `test_C_libtooling-hrts`**, not taken alongside this file
; (round-2 F-F2-2 option (b)). **THE DAY
; IT LANDS, THIS FILE'S STRING CHANGES BACK to the `taint escape … classical-
; condition phi` one above. That is the FIX ARRIVING, not a regression:
; re-derive the header argument, flip the expectation here, and keep the module —
; it is the only thing in the tree that can see either edit.** Equally: if this
; file ever ACCEPTS, the skip has been deleted rather than made precise, and the
; back-edge pair is the first thing to re-measure.
;
; ⚠ The IR-text `CHECK-NOT`s below are VACUOUS BY CONSTRUCTION and are kept only
; as belt-and-braces: a `DS_Error` decline writes 0 bytes to stdout, so what pins
; this file is the `not` inversion on the RUN line plus the message match
; (Rule 12(b)).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %arg) {
entry:
  %g = icmp sgt i32 %arg, 100
  br i1 %g, label %pre, label %Y
pre:
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %c = icmp eq i32 %q, 7
  br i1 %c, label %armB, label %mB
armB:
  %tb = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  br label %mB
mB:
  %MB = phi i32 [ %tb, %armB ], [ 0, %pre ]
  %dz = zext i32 %q to i64
  %dd = add i64 %dz, -7
  %mz = zext i32 %MB to i64
  %pm = mul i64 %dd, %mz
  %u = trunc i64 %pm to i32
  %m0 = call i32 @cq_measure_si32(i32 %MB)
  br label %J
Y:
  br label %J
J:
  %p = phi i32 [ %u, %mB ], [ 0, %Y ]
  %mp = phi i32 [ %m0, %mB ], [ 0, %Y ]
  %x2 = call i32 @cq_measure_si32(i32 %p)
  %s = add nsw i32 %mp, %x2
  ret i32 %s
}

; CHECK: error: {{.*}}cq controlled lowering: state prep seed is proven equal to the condition register under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled
; CHECK-NOT: cqrt_alloc_i32
