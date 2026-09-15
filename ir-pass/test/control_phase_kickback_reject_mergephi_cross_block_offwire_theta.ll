; control_phase_kickback_reject_mergephi_cross_block_offwire_theta.ll — DECLINE
; (bd `test_C_libtooling-hn29` / `-leyd` / `-52og`, Track P′). THE ONE FILE THAT
; SHOWS THE CFG-BOUNDED POSITIONAL SCAN IS NOT REDUNDANT WITH THE WIRE WALK.
;
; THE SHAPE: the cross-block prep-merge-φ kickback with a chained
; `cq_theta_i1(%b0, …)` in the intervening block — a NON-DIAGONAL Ry on a live
; handle that is NOT on the condition φ's provenance wire (`condProvenance(%b1)`
; is `{%b1, %t}`; `%b0` is a different rail and no forward user edge reaches it).
;
; ⚠ SO `wireGainsNonDiagonalGate` CANNOT SEE THIS GATE, IN EITHER MODE. What
; declines it is `chainedThetaBetweenDefAndBranch`, and before Track P′ it was
; `condWireDisposition`'s unconditional `Cond->getParent() != R.Pred` bail. That
; is the P5 prong's documented job — *"the positional scan fires even for a theta
; on ANOTHER wire, which no wire walk can see"* — and this file is the cross-block
; half of it. Over-declining an off-wire gate is safe (Prime Directive); the
; point of the file is that the scan STILL FIRES after the widening, so the
; widening cost nothing on this axis.
;
; ⚠ WHAT WOULD MAKE THIS FILE GO GREEN FOR THE WRONG REASON. If someone
; "simplifies" the φ by giving it `railCondWireDisposition`'s treatment (which
; drops the positional prong entirely, on a structural ground argued about a
; `cq_theta_i1` NAME and explicitly refused for a φ by bd `4aiu`), this module
; ACCEPTS and nothing else in the tree notices. Do not transplant that ground.
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
  %x = call i1 @cq_theta_i1(i1 %b0, double 7.000000e-01)
  br label %gap2
gap2:
  br i1 %b1, label %ph, label %done
ph:
  call void @cq_phi(double 9.000000e-01)
  br label %done
done:
  %m = call i1 @cq_measure_i1(i1 %x)
  ret i1 %m
}

; CHECK: cq controlled lowering: condition predates a non-diagonal gate under quantum control
