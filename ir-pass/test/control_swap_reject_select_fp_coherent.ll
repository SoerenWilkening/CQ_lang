; control_swap_reject_select_fp_coherent.ll — DECLINE (fp-data-select-PRD §5
; matrix 4): an fp select operand FEEDING a downstream rotation on its wire
; (arg-0) beyond the select — channel B of the §16.7 coherent-operand default.
; The rotation's interference would observe the operand's coherence, which the
; basis CNOT copy breaks. Gate 5 (`hasCoherentDownstreamUse`, the forward walk)
; fires — type-agnostic, unchanged by the gate-4 fp un-staging.
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

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @example(double %u0, double %v0, double %x) {
entry:
  %q   = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %y   = call double @cq_theta_f64(double %v0, double 2.500000e-01)
  %c   = fcmp ogt double %y, 5.000000e+00
  %sel = select i1 %c, double %q, double %x
  %qd  = call double @cq_theta_f64(double %q, double 3.000000e-01)  ; channel B
  %ms  = call double @cq_measure_f64(double %sel)
  %md  = call double @cq_measure_f64(double %qd)
  ret double %ms
}
