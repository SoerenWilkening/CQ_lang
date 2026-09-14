; control_inplace_ry_reject_stateprep_backedge_phidesc_collider.ll — DECLINE (F2),
; and it is THE TRIPWIRE for the BACK-EDGE φ hole in the 2026-09-14
; phi-descendant narrowing (bd `test_C_libtooling-om35`, round-1 Rule-13 review
; finding F-F1-1).
;
; THIS FILE IS HALF OF A PAIR. Its twin is
; `control_inplace_ry_reject_stateprep_backedge_nonphidesc_collider.ll`, which is
; THIS module with ONE operand changed (there the loop-carried phi's back-edge
; incoming reads `%carryX = icmp sgt i32 %k, 2`, a CONDITION-derived value;
; here it reads `%carry = icmp sgt i32 %s, 2`, which reads the region's own merge
; phi `%m`). Everything else is identical. The twin is the ISOLATING CONTROL, not
; a second tripwire: it declines with the SAME string on every binary in this
; family, which is what makes the string on THIS file attributable to
; phi-descendant MEMBERSHIP and to nothing about the loop.
;
; WHAT IT PINS, AND WHY THE NARROWING EXISTS. `PhiDesc` excludes the transitive
; SSA USER closure of the region's own merge phi `%m`, on the AVAILABILITY
; ground: such a value's OPERANDS reach `%m`, which is defined at the join, so it
; cannot be SPELLED at either slot F2's question is about (the arm theta's arg-0,
; or the merge phi's pred-edge incoming). That argument is a theorem only for an
; ACYCLIC user chain. A phi is the one opcode whose operand need only dominate
; its incoming EDGE — so `%v`, a LOOP-HEADER phi taking the `%m`-descendant
; `%carry` on the BACK EDGE, is in the user closure and yet DOMINATES the arm and
; the pred edge, i.e. IS available at both slots. It is a genuine collider: it is
; tainted, it is in `Cand`, and on the true edge it is pinned to `false` = the
; arm's seed.
;
; MEASURED (`trackF/fix_r1_probes/run3.sh`, three binaries, byte sizes printed):
;   * the frozen 2026-09-14 ORACLE (`cq-opt` sha256 f7b65d8c…, from 59ac5b7),
;     which has no phi-descendant exclusion at all: F2, this string.
;   * the UN-NARROWED subject (sha256 147cb3d6…, the conjunct without the
;     dominance skip): `control flow inside a loop body` — F2 did NOT fire. A
;     MOVER, and the ground falsified by construction.
;   * the narrowed subject: F2 again, this string. The mover is gone.
; Attribution control `trackF/fix_r1_probes/p8b_nocollider.ll` (this module with
; `%v` deleted, so the only candidate is `%carry` itself) declines at the loop
; fence on the narrowed subject — deliberately: `%carry` is a NON-phi user, SSA
; already puts it in a block dominated by `%m`'s, it is unavailable at both slots,
; and excluding it is exactly what the availability ground licenses. So the F2
; that fires on THIS file is on `%v` and on nothing else.
;
; ⚠ CORRECTED 2026-09-14c (X5 re-derivation). THIS HEADER USED TO SAY "this file
; is declined TWICE OVER today, [because] every IN-LOOP state prep is stopped
; before F2 by bd `test_C_libtooling-wx8g`". **THAT WAS FALSE WHEN IT WAS
; WRITTEN, AND THIS FILE'S OWN MEASUREMENTS ABOVE CONTRADICT IT** — they record
; F2 firing on the pre-`wx8g` ORACLE. The carve-out `wx8g` retired was
; `if (RailCond && Region.InLoop)`, guarded on a BARE RAIL; this module's
; condition is a COMPARE (`%c = icmp eq i32 %q, 7`), so it was never behind that
; fence at all. The consequence matters: **this pair holding across the `wx8g`
; landing is NOT evidence about the spelling the trigger below was written for.**
; The bare-rail spelling is measured separately — see the replacement trigger.
;
; ⚠ RETIREMENT TRIGGER (L8), BY NAME — **FIRED, AND DISCHARGED**. It read: "bd
; `test_C_libtooling-wx8g`. The day the in-loop state prep lands, re-derive
; `collectStatePrepPhiDescendants`' dominance skip against the shapes `wx8g`
; admits — DO NOT assume the phi case is the only cyclic one — and re-measure
; this pair first." `wx8g` landed 2026-09-14 (`a2b86139`); the pair was
; re-measured and HELD (byte-identical `CQ_CTRL_DBG` anchor); the re-derivation
; was done in session 2026-09-14c (`trackX/X5_REDERIVATION.md`) and its result
; is written into `collectStatePrepPhiDescendants`' header — the skip is sound
; because every member's block is dominated by `MergeBB` BY INDUCTION, and
; cyclicity is not a term in that argument. The bare-rail three-way isolation
; `trackX/probes/w3` / `w3b` / `w3c` is the measurement this file could not make.
; ⚠ THE LIVE OBLIGATION ON THIS FILE IS UNCHANGED: **if its string changes to
; anything other than F2's, the narrowing has been lost, not widened.**
;
; ⚠ **THE PREDICATE THIS FILE PINS WAS REPLACED ON 2026-09-15 AND THIS FILE DID
; NOT MOVE — THAT IS THE POINT OF IT.** bd `test_C_libtooling-hrts` / bd
; `test_C_libtooling-l3i1` (the precision fix) and bd `test_C_libtooling-dpau`
; (the opcode filter) landed together: `!DT.dominates(MergeBB, I->getParent())`
; is gone, and `collectStatePrepPhiDescendants` now asks
; `availableAtAnF2Slot(I, PredSlot, ArmSlots, DT)` of EVERY user. The old line
; was a SUFFICIENT proxy for "unavailable at both of F2's slots" and not a
; NECESSARY one, so it also dropped phis that were unavailable and merely sat off
; `MergeBB`'s dominance subtree — an OVER-DECLINE, whose tripwire
; `control_inplace_ry_reject_stateprep_acyclic_nondominated_phi.ll` has now
; flipped to the taint-escape string exactly as its own header instructed.
;
; THIS MODULE IS THE OTHER DIRECTION AND IT IS THE ONE TO BE AFRAID OF. `%v` is a
; LOOP-HEADER phi that takes the `M`-descendant on its BACK EDGE while sitting in
; a block that DOMINATES both slots — i.e. it is AVAILABLE, hence a GENUINE
; RIVAL, hence must NOT be excluded. Under the new predicate it is skipped by
; `DT.dominates(I, PredSlot)` firing, and the walk TRUNCATES there (its users are
; not enqueued either) — which is REQUIRED and not merely conservative: a user
; `f(%v)` is spellable at the slot because `%v` is a register available there.
; MEASURED at the landing: this file and its `nonphidesc` twin BOTH keep F2's
; string, on the ORACLE (`cq-opt` sha256 `0e280fc6...`) and on the subject
; (`8cda04ca...`) alike.
;
; ⚠ THE CYCLIC / ACYCLIC FRAMING THE EARLIER TEXT HERE USED IS RETIRED (X5,
; 2026-09-14c, and confirmed by the landing). Cyclicity is not a term in the
; argument; AVAILABILITY is. This module is simply the sub-case where the
; candidate IS available at a slot, and `r20_acyclic_nondominated_phi.ll` the
; sub-case where it is not. A reader who re-derives only against loop shapes will
; have re-derived half a predicate.
;
; ⚠ LIVE OBLIGATION, UNCHANGED AND NOW SHARPER: **if this file's string changes
; to anything other than F2's, the exclusion has been widened past availability
; and that is an OVER-ACCEPT, not a capability win.** The ACCEPT direction of the
; same line is pinned by `control_inplace_ry_stateprep_acyclic_nondominated_phi_
; accept.ll`; a change that flips that file without flipping this one is the fix,
; and a change that flips this one is the bug.
;
; ⚠ The IR-text `CHECK-NOT`s below are VACUOUS BY CONSTRUCTION and are kept only
; as belt-and-braces: a `DS_Error` decline writes 0 bytes to stdout, so what pins
; this file is the `not` inversion on the RUN line plus the message match
; (Rule 12(b)).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

define i32 @main() local_unnamed_addr {
entry:
  br label %loop

loop:
  %i = phi i32 [ 0, %entry ], [ %inext, %join ]
  %v = phi i1 [ false, %entry ], [ %carry, %join ]
  %q = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 3.000000e-01)
  %k = add nsw i32 %q, -5
  %c = icmp eq i32 %q, 7
  br i1 %c, label %arm, label %join

arm:
  %t = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01)
  br label %join

join:
  %m = phi i1 [ %t, %arm ], [ false, %loop ]
  %s = select i1 %m, i32 1, i32 %k
  %carry = icmp sgt i32 %s, 2
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %inext, 3
  br i1 %done, label %exit, label %loop

exit:
  %r = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %m)
  %rv = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %v)
  %z = zext i1 %r to i32
  %zv = zext i1 %rv to i32
  %a = add nsw i32 %z, %zv
  ret i32 %a
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef)
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare zeroext i1 @cq_measure_i1(i1 noundef zeroext)

; CHECK: error: {{.*}}cq controlled lowering: state prep seed is proven equal to the condition register under quantum control
; CHECK-NOT: cqrt_ry_i1_controlled
; CHECK-NOT: cqrt_alloc_i1
