; control_swap_reject_select_phase_operand.ll — DECLINE: a tainted-condition
; integer-data `select` whose value OPERAND is itself a relative-phase (Rz)
; carrier (a `cq_phi` result). The WI-3 Rule-13 adversarial-review BLOCKER (the
; gate-5 backward half).
;
; `(y>5) ? cq_phi(q) : x` — the true operand `%qd = cq_phi(%q, 0.7)` carries a
; COMPLEX relative phase ((|0> + e^{i0.7}|1>)/sqrt2 after the Ry). The
; controlled-XOR copy merge is a CNOT basis copy — it copies a basis LABEL, not a
; phase (Rule 7) — so copying %qd into %out would DEPHASE it: %out's marginal is
; Z-decohered and a downstream basis change (e.g. Ry(-pi/2) then measure) yields
; the WRONG distribution (P(0)=0.5 instead of ~0.822) while `opt -verify` stays
; clean — the verify-clean silent-miscompile class.
;
; Gate 5's forward-only `hasCoherentDownstreamUse` proxy MISSED this (it inspects
; an operand's downstream USES, never its PRODUCER); `operandCarriesPhase` is the
; backward twin that declines any operand whose lineage contains a `cq_phi`. The
; logically-equivalent rotation-AFTER-select shape (q feeds a downstream cq_phi)
; already declines via the forward proxy (control_swap_reject_select_coherent.ll);
; this fixture closes the rotation-BEFORE-select mirror so both decline.
;
; A pure `cq_theta` (Ry) operand is a REAL-amplitude basis superposition (NO
; relative phase) and copies through the CNOT correctly — the canonical
; `(q>5)?q:x` accept (control_swap_select_qc.ll) MUST survive; the backward walk
; stops at theta. See [[select-merge-phase-operand-dephasing]].
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
; nothing is emitted for the declined select (Prime Directive — lower nothing):
; CHECK-NOT: cqrt_copy
; CHECK-NOT: cqrt_alloc
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %v0, i32 %x) {
entry:
  %q   = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %qd  = call i32 @cq_phi_si32(i32 %q, double 7.000000e-01)   ; phase-carrying operand
  %y   = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %c   = icmp sgt i32 %y, 5
  %sel = select i1 %c, i32 %qd, i32 %x
  %m   = call i32 @cq_measure_si32(i32 %sel)
  ret i32 %m
}
