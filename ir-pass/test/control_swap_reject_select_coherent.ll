; control_swap_reject_select_coherent.ll — DECLINE: a COHERENT-operand select
; (4.4 WI-1 gate 5, the §16.7 conservative default; the channel-B dephasing
; case). A tainted value operand whose lineage ALSO feeds a downstream rotation
; cannot be safely CNOT-copied into the merge: the copy entangles `%out` (channel
; A) AND kills the operand's own marginal off-diagonal so the standalone
; downstream rotation is dephased (channel B). The shipped v1 default declines
; `control flow`; the exact coherent-vs-basis boundary is the binding §8 Rule-13
; clearance item, widened only by independent review — a green suite does NOT
; authorize widening this gate.
;
; `(y>5) ? q : x` where `%q` ALSO feeds a downstream `cq_theta(&q, .9)`: the
; operand `%q` has a quantum use beyond the select, so `hasCoherentDownstreamUse`
; flags it. Gate 3 (angle) passes — `%sel` itself feeds only a measure — and
; gate 4 passes (i32), so the decline is squarely gate 5.
;
;
; ===========================================================================
; 3qlq(prep_a2): HAND DECISION — RE-SPELLED with `cq_theta` as the downstream
; rotation, and RESTRUCTURED so the condition reads its OWN register.
;
; Gate 5 has TWO channels and only ONE of them dies with D1. Channel A ("the
; operand CARRIES a relative phase") required a value to carry a phase, which the
; register-free surface abolishes. Channel B — "the operand's WIRE is rotated
; somewhere else, so the copy-merge would dephase the answer" — is about a
; ROTATION on the wire and is spelled with `cq_theta` exactly as well as it was
; with `cq_phi`. This file is channel B.
;
; ⚠ WHY THE CONDITION NEEDED A SECOND REGISTER, measured: the naive swap
; (`cq_phi_<sfx>` -> `cq_theta_<sfx>` in place) makes the compare read a register
; that a NON-DIAGONAL gate later rewrites, so `condition predates a non-diagonal
; gate` fires FIRST and gate 5 is never reached. Rz was diagonal and Ry is not —
; that is the one substantive difference between the two stems, and it shows up
; here rather than in the property being pinned.
;
; ⚠ DISCRIMINATOR, measured both ways ($SP/progress/prep_a2_work/pv/):
;   * WITH the downstream rotation on the operand's wire: exit 1, the string below.
;   * WITHOUT it (the identical module with the rotation replaced by a plain
;     arithmetic op on the same value): exit 0, ACCEPTS.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: control flow under quantum control

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %v0, i32 %x) {
entry:
  %q   = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %y   = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %c   = icmp sgt i32 %y, 5
  %sel = select i1 %c, i32 %q, i32 %x        ; operand %q is ALSO rotated below
  %qd  = call i32 @cq_theta_si32(i32 %q, double 9.000000e-01)  ; channel B
  %ms  = call i32 @cq_measure_si32(i32 %sel)
  %md  = call i32 @cq_measure_si32(i32 %qd)
  %r   = add i32 %ms, %md
  ret i32 %r
}
