; control_inplace_ry_reject_stateprep_acyclic_nondominated_phi.ll — DECLINE, and
; since 2026-09-15 it declines at `declineClassicalMuxes`, NOT at F2. **THE L8
; RETIREMENT TRIGGER THIS FILE WAS COMMITTED WITH HAS FIRED AND THIS IS THE FIX
; ARRIVING, NOT A REGRESSION** — bd `test_C_libtooling-hrts` / bd
; `test_C_libtooling-l3i1` landed the precise predicate (member-vs-SLOTS) in
; `collectStatePrepPhiDescendants`. The file's own instruction was: *"THE DAY IT
; LANDS, THIS FILE'S STRING CHANGES BACK to the `taint escape … classical-
; condition phi` one … re-derive the header argument, flip the expectation here,
; and keep the module — it is the only thing in the tree that can see either
; edit."* That is exactly what this header does; the module is BYTE-UNCHANGED.
;
; WHAT THIS MODULE IS, AND IT CONTAINS NO LOOP ANYWHERE. `%g = icmp sgt i32
; %arg, 100` is an opaque classical guard that bypasses the state-prep diamond
; (`%entry -> %Y -> %J`). `%u` in the merge block `%mB` is an `%MB`-descendant
; folding to `{0}` == the seed. `%p = phi i32 [ %u, %mB ], [ 0, %Y ]` sits in
; `%J`, which `%mB` does NOT dominate — with no back edge, no latch, no cycle:
; `entry -> {pre, Y}; pre -> {armB, mB}; armB -> mB; mB -> J; Y -> J; J -> ret`.
;
; WHY THE VERDICT MOVED, IN ONE SENTENCE. `%p` is unavailable at BOTH of F2's
; slots (it neither dominates `%pre`'s terminator nor lies in a block dominating
; `%armB`), so it is a LICENSED exclusion — a value the author could not have
; spelled at the arm theta's arg-0 or on the merge φ's pred edge in ANY module —
; and the old proxy `!DT.dominates(MergeBB, I->getParent())` dropped it from the
; exclusion set anyway, purely because its block sits off `%mB`'s dominance
; subtree. F2 then counted it as a rival and declined. The slot test keeps it
; excluded, F2 goes silent, and the module falls through to the pre-existing
; `declineClassicalMuxes` decline that was ALWAYS underneath it.
;
; ⚠ THE MODULE STILL DECLINES, AND THAT IS THE HONEST STATE OF THIS CAPABILITY.
; `%p` is a tainted φ under a CLASSICAL condition and is not one-register
; liftable, so the top-level verdict does not become an ACCEPT. Say it in those
; words and do not upgrade it: what this file witnesses is that **F2 stopped
; counting a licensed non-witness**, not that a program was recovered. Track F′
; re-attempted the ACCEPT construction X5 had failed at (2026-09-15,
; `IMPL_F2.md` §5) and failed again, for a reason that now looks structural
; rather than accidental — a φ in a block not dominated by `MergeBB` that
; carries an `M`-descendant is necessarily a tainted classical-condition mux, or
; else sits under a branch detection refuses as nested. **That is an argument,
; not a theorem** (L5), and the mask it names — `declineClassicalMuxes` — is
; under active widening pressure (the one-register lift, bd `test_C_libtooling-
; xdu2`'s rail bank). The day that mask moves, this over-decline would have
; become a lost ACCEPT with no diagnostic anywhere; it is fixed now for that
; reason as much as for this file's string.
;
; ⚠ NON-VACUITY IS PINNED BY A SIBLING, NOT BY THIS FILE. A decline fixture that
; goes green on a NEW string can be green because its subject vanished
; (fixture-hygiene defect (c)). The isolating control is
; `control_inplace_ry_reject_stateprep_acyclic_nondominated_phi_control.ll`: the
; SAME module with ONE operand changed (`%mz = zext i32 %q` in place of
; `zext i32 %MB`) so `%p` carries a value that is NOT an `M`-descendant. It
; declines AT F2, on BOTH the 2026-09-15 ORACLE (`cq-opt` sha256 `0e280fc6…`)
; and the subject (`8cda04ca…`). So F2 can still fire on this exact shape, and
; what moved here is φ-descendant MEMBERSHIP and nothing else.
;
; ⚠ RETIREMENT TRIGGER (L8), REPLACING THE ONE THAT FIRED. If this file's string
; ever goes BACK to F2's, the slot test has been reverted to a `MergeBB`-proxy
; or the availability argument has been narrowed — re-derive
; `collectStatePrepPhiDescendants`' header from scratch and re-measure the
; back-edge pair `control_inplace_ry_reject_stateprep_backedge_{phi,nonphi}desc_
; collider.ll` in the same round. If it ever ACCEPTS, the exclusion has been
; widened past availability (or `declineClassicalMuxes` has moved under it):
; that is the ACCEPT this capability was always one mask away from, and it needs
; its own Rule-13 round before it is believed.
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

; CHECK: error: {{.*}}cq taint escape: tainted value muxed by a classical-condition phi
; CHECK-NOT: cq controlled lowering: state prep seed is proven equal
; CHECK-NOT: cqrt_ry_i32_controlled
; CHECK-NOT: cqrt_alloc_i32
