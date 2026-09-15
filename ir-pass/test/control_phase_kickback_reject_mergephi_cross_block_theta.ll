; control_phase_kickback_reject_mergephi_cross_block_theta.ll — DECLINE
; (bd `test_C_libtooling-hn29` / `-leyd` / `-52og`, Track P′). THE FENCE THAT
; REPLACED THE CROSS-BLOCK BAIL, MEASURED WITH TEETH.
;
; THE SHAPE: `control_phase_kickback_reject_mergephi_cross_block.ll`'s module —
; a prep merge φ read by a kickback whose `Pred` is TWO blocks later — with ONE
; instruction added: a CHAINED `cq_theta_i1(%b1, …)` in the intervening block.
;
; WHY IT EXISTS. Track P′ replaced `condWireDisposition`'s
; `Cond->getParent() != R.Pred → DeclineNow` (for a CLAIMED prep merge φ only)
; with `chainedThetaBetweenDefAndBranch`, a CFG-bounded forward scan. The
; sibling file is the ACCEPT that widening produces; this is the proof the
; widening did not BUY that accept by deleting the fence, which is what both
; beads and that file's own retirement trigger forbid in those words. The scan
; walks the tail of the φ's block, then every block that can still reach `Pred`,
; then `Pred` up to its terminator — so the theta in `gap1` is found and the
; module declines with the SAME string the whole family has always used.
;
; ⚠ THIS ONE IS DOUBLY COVERED AND ITS SIBLING IS NOT, AND THAT IS MEASURED RATHER
; THAN ASSERTED. The gate here also sits on the φ's own PROVENANCE WIRE, so
; `wireGainsNonDiagonalGate` refuses it even with no positional prong at all:
; SOURCE MUTATION S-M2 (`trackP/probes/source_mutation.sh`) makes the cross-block
; walk `return false` outright, and **this file stays red while
; `…_cross_block_offwire_theta.ll` goes green**. It is kept because it pins the
; ordinary case; `…_cross_block_offwire_theta.ll` is the file to read if the
; positional prong is ever suspected of being redundant, and
; `…_inloop_latch_theta.ll` is the same distinction one clause over.
;
; ⚠ Rule 12(b): a `DS_Error` decline writes 0 bytes to stdout, so every IR-text
; negative a decline fixture could carry is VACUOUS. What pins "no silent
; lowering" is the `not` inversion on the RUN line (exit non-zero) plus the
; string, mirrored character-for-character below.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

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
  br label %gap1
gap1:
  %c = call i1 @cq_theta_i1(i1 %b1, double 7.000000e-01)
  br label %gap2
gap2:
  br i1 %b1, label %ph, label %done
ph:
  call void @cq_phi(double 9.000000e-01)
  br label %done
done:
  %m = call i1 @cq_measure_i1(i1 %c)
  ret i1 %m
}

; CHECK: cq controlled lowering: condition predates a non-diagonal gate under quantum control
