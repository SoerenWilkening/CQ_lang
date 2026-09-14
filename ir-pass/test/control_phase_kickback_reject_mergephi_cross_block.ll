; control_phase_kickback_reject_mergephi_cross_block.ll — DECLINE (bd `3qps`,
; Track P). THE ORDER FENCE, AND IT IS THE REASON THIS EMITTER NEEDS NO RE-READ
; OF A REWRITTEN CONDITION.
;
; THE SHAPE: the phase consumer's `br` is NOT in the prep's merge block — a block
; sits between them — so the kickback's `Pred` is not the prep's `MergeBB`.
;
; WHY THAT MATTERS AND IS NOT A TIDINESS CHECK. A merge-φ-conditioned kickback is
; SOUND only because the bd `hcrg` alias pre-flight sees `A.Pred == B.MergeBB`
; and takes the sanctioned `sequentialChainAlias` edge `Precedes[kickback] =
; {prep}` — so the KICKBACK is emitted FIRST, while the φ is still live, and the
; prep's later M-β RAUW rewrites the emitted gate's operand to the hoisted theta.
; Break the adjacency and that edge does not fire: nothing then orders the two,
; and a prep emitted first would have RAUW'd the branch operand and FREED the φ
; in `flattenRegion`. The premise is therefore CHECKED rather than assumed —
; `condWireDisposition` declines a condition defined outside `R.Pred`
; ("unbounded gap across blocks"), and the tree spelling asks the same of every φ
; leaf. No ordering can be silently wrong, because the shape that would need one
; never reaches the emitter.
;
; ⚠ THIS ALSO OWNS TWO SHAPES A READER WILL LOOK FOR HERE: a SECOND kickback
; whose own `br` reads the same φ from a later block, and TWO prep φ conjoined
; when the second prep's diamond pushes the first φ out of `Pred`
; (`trackP/probes/p20.c`). Both are ACKNOWLEDGED OVER-DECLINES of valid circuits
; — the Kahn order would in fact schedule every one of those kickbacks before
; every prep. RETIREMENT TRIGGER: they become accepts when the positional prong
; is given a real CFG-bounded scan (all blocks on paths from the φ's block to
; `Pred`, visited-set bounded) instead of the single-block window it has today.
; That is a new walk and needs its own Rule-12 probe family and Rule-13 round; it
; is NOT to be bought by simply deleting this fence.
;
; ⚠ ORACLE: `branch phase on a bare i1 condition` at `59ac5b7` — string moves,
; disposition does not.
; ⚠ Rule 12(b): a `DS_Error` decline writes 0 bytes to stdout, so every IR-text
; negative a decline fixture could carry is VACUOUS. What pins "no silent
; lowering" is the `not` inversion on the RUN line (exit non-zero) plus the
; string, mirrored character-for-character below.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

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

; CHECK: cq controlled lowering: condition predates a non-diagonal gate under quantum control
