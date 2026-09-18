; loop_pairing_reject_round2_falsified.ll — DECLINE (bd `test_C_libtooling-tu9q`,
; 2026-09-15). THE L1 WINDOW OF THE ROUND-1 ROOT-MINT GRANT, AND ITS WITNESS.
;
; `lowerLoops` offers `markIfRailLocal` the root-mint escape at ROUND-1 TAINT
; (`CQLoweringPass.cpp:455`), and `repropagateControlMerges` (`:571`) then re-seeds
; taint from the 6.5/4.5 merge `%out` rails and runs control detection + lowering
; to a fixpoint. Round-2 taint is a strict SUPERSET, and EVERY clause of
; `railLocalQualifies` is a REFUSAL over tainted values — so a grant made at round
; 1 can be FALSIFIED by round 2 with nothing to notice. That is `CLAUDE.md` L1's
; PREDICATE species verbatim, and `declineRound2FalsifiedRailGrants` is its cure:
; RECORD at the site that asks, RE-ASK after the fixpoint, in BOTH entry points,
; decline LOUDLY.
;
; THE MODULE. A 6.5 classical-call arm sits OUTSIDE the loop; the loop body reads a
; value DERIVED from its merged result (`%m2 = mul i32 %m, 2`). At `lowerLoops` —
; which runs BEFORE `detectControlRegions` — the merge phi's incomings are a
; CLASSICAL call result and a constant, so `%m` is untainted, `%m2` is an untainted
; `mul` of two untainted values, neither is a `Cand`, and the loop is granted the
; marking on the root mint `%y` alone. After the fixpoint `%m` is the emitter's
; `cqrt_alloc_i32`-minted `%out` rail and `%m2` is a tainted `cq_template_mul_i32_hl`
; rail DEFINED OUTSIDE the loop and READ AS DATA inside it.
;
; ⚠ WHY THE DECLINE IS THE CORRECT DIRECTION AND NOT A CONSERVATISM. `%m2`'s
; forward gate is in the loop PREHEADER and runs ONCE, while a marked body's
; discharge point runs K times. `Uncomputation.cpp`'s §4/§2.9 pair asks each
; endpoint SEPARATELY whether it repeats and never whether the two repeat EQUALLY
; (`Uncomputation.cpp:982-1000` says so in those words), so leaving the grant
; standing is **K adjoints against ONE forward gate** — an over-reversed rail, a
; wrong unitary, not a leak. It is the same shape
; `loop_pairing_reject_root_hoisted_template_data.ll` refuses at round 1, reached
; through the round-2 taint delta instead.
;
; ⚠ THE RE-ASK RE-DERIVES ITS ROOTS UNDER FINAL TAINT BEFORE REFUSING, and the
; SIBLING of this file is why (Track T finding T-1). `probes/adv/l1_round2_grow_
; 65arm.ll` is the identical module with the body reading `%m` ITSELF rather than
; `%m2`; there the round-2-tainted value IS the emitter's `%out` rail, which
; `invariantRegisterRootsImpl` clause (ii-b) ADMITS as a merge out-rail — the grant
; is still justified, just by a root the round-1 record could not name — and that
; module ACCEPTS. Re-asking with the ROUND-1 roots alone declined it, which was an
; OVER-DECLINE and was fixed. **Keep both**: one file pins the refusal and the
; other pins that the refusal is not indiscriminate.
;
; ⚠ AND IT PROVES THE WINDOW IS REACHABLE. A fence written for an L1 window nobody
; can construct is a prediction, not a test (`CLAUDE.md` L10). On ORACLE
; `0e280fc62a91cec2…` this module declines with bd `s82e`'s string (the loop is
; never marked there at all); on this branch it declines with the string below,
; which is only emitted when a round-1 grant was really made and really falsified.
;
;
; ⚠ THE `not` INVERSION ON THE RUN LINE IS WHAT PINS THE DECLINE. A `DS_Error`
; decline writes 0 bytes to stdout, so an IR-text `CHECK-NOT` here would be VACUOUS
; (Rule 12 fixture-hygiene defect (b)); the property is the non-zero exit plus the
; character-for-character message below.

; ⚠⚠ CONVERTED DECLINE -> ACCEPT, 2026-09-21, bd `test_C_libtooling-4jok`, WHEN
; bd `tu9q` P0+P3 LANDED.  READ THIS BLOCK FIRST; EVERYTHING BELOW IT IS KEPT
; VERBATIM AND ITS CENTRAL ARGUMENT IS NOW HISTORY.
;
; THE OLD GROUND, verbatim from below: *"`%m2`'s forward gate is in the loop
; PREHEADER and runs ONCE, while a marked body's discharge point runs K times …
; leaving the grant standing is **K adjoints against ONE forward gate** — an
; over-reversed rail, a wrong unitary, not a leak."*
;
; ⚠ THAT WAS TRUE OF A TREE WITHOUT P1 AND P2, AND IT IS THE POINT OF THE FILE
; THAT IT WAS TRUE.  bd `tu9q`'s P1 (`multiplicityAgrees`) is exactly the missing
; test the old header says `Uncomputation.cpp:982-1000` specifies, and P2
; (`anchorForConsumer`'s loop-exit placement) is exactly the right point.
; MEASURED on `cq-opt` 3368af12…:
;
;     entry:  %h_op = call i32 @cq_template_mul_i32_hl(i32 %out1, i32 2)    <- ONE mint
;     loop:   … the per-trip `lshr` rail minted, `_unc`'d and freed each trip …
;     out:    call void @cq_template_mul_i32_hl_unc(i32 %h_op, i32 %out1, i32 2)  <- ONE adjoint
;             call void @cqrt_free(i32 %h_op)
;
; ONE forward, ONE adjoint, in the loop's unique EXIT block.  Stage 2b:
; `4 template rail mint(s) of which 0 left dirty`.  The predicted over-reversal
; does not occur, so the decline had to go.
;
; ⚠⚠ BUT `declineRound2FalsifiedRailGrants` DID NOT GO, AND THIS FILE WAS ITS ONLY
; PIN IN 2109 FIXTURES.  It is still called at BOTH entry points
; (`CQLoweringPass.cpp:829` / `:1313`).  The old header names a SECOND job that
; this accept destroys — *"AND IT PROVES THE WINDOW IS REACHABLE.  A fence written
; for an L1 window nobody can construct is a prediction, not a test
; (`CLAUDE.md` L10)"* — and an L1 cure is the class this project keeps losing to.
; **THE REPLACEMENT IS `loop_pairing_reject_round2_falsified_postloop_read.ll`**,
; which is this module plus one post-loop read of `%m2` (so (ii-d)'s
; `allUsersInside` conjunct is false, the root is refused, and the grant stays
; falsified).  It fires character-for-character on BOTH binaries.  **Do not delete
; that file while this one is an accept**; independently constructed and measured
; by the orchestrator and by Rule-13 round 5 (F-4), which is why it is one file
; and not two.
;
; ⚠ THE SIBLING CONTROL IS UNCHANGED and still matters: the old header pairs this
; with `trackT/probes/adv/l1_round2_grow_65arm.ll` (*"one file pins the refusal
; and the other pins that the refusal is not indiscriminate"*).  That module
; ACCEPTS at exit 0 on both binaries, as it did before.  The pair is now
; replacement-file / sibling rather than this-file / sibling.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.r0.ll
; RUN: %filecheck %s --check-prefix=MINT < %t.r0.ll
; RUN: %filecheck %s --check-prefix=EXITD < %t.r0.ll
; RUN: %filecheck %s --check-prefix=MCNT < %t.r0.ll
;
; THE MINT IS OUTSIDE THE LOOP — in `entry`, immediately after the merge that
; produces its operand, and nothing in the loop re-mints it:
; MINT: %[[P:.*]] = call i32 @cq_template_mul_i32_hl(i32 %[[O:.*]], i32 2)
;
; THE ADJOINT IS IN THE LOOP-EXIT BLOCK, once, paired with its free.  This is P2's
; placement and it is the ONLY thing that makes the accept defensible:
; EXITD: call void @cq_template_mul_i32_hl_unc(
; EXITD-NEXT: call void @cqrt_free(
;
; THE MULTIPLICITY CENSUS, whole-file, its own prefix so nothing windows the
; negative (Rule 12 fixture-hygiene (a)).  **A SECOND `mul` ADJOINT IS THE EXACT
; WRONG UNITARY THIS FILE USED TO PREDICT**, so this line is the old header's
; hazard turned into a live assertion rather than deleted with it:
; MCNT-COUNT-1: call void @cq_template_mul_i32_hl_unc(
; MCNT-NOT: call void @cq_template_mul_i32_hl_unc(
;

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @f(i32 %a) #0 {
  %s = add i32 %a, 100
  ret i32 %s
}

define i32 @slice(i32 %u0, i32 %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %y = call i32 @cq_theta_si32(i32 7, double 3.000000e-01)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @f(i32 %a)
  br label %merge
merge:
  %m = phi i32 [ %r, %arm ], [ 5, %entry ]
  %m2 = mul i32 %m, 2
  br label %loop
loop:
  %k = phi i32 [ 1, %merge ], [ %k2, %loop ]
  %acc = phi i32 [ 0, %merge ], [ %s2, %loop ]
  %sh = lshr i32 %y, %k
  %an = and i32 %sh, %m2
  %ms = call i32 @cq_measure_si32(i32 %an)
  %s2 = add i32 %ms, %acc
  %k2 = add i32 %k, 1
  %e = icmp eq i32 %k2, 3
  br i1 %e, label %out, label %loop
out:
  %y2 = call i32 @cq_theta_si32(i32 %y, double 9.000000e-01)
  %mm = call i32 @cq_measure_si32(i32 %y2)
  %t = add i32 %s2, %mm
  ret i32 %t
}

attributes #0 = { nounwind willreturn memory(none) }
