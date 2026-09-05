; control_swap_reject_select_fp_phase_sibling_alias.ll — DECLINE (kjd1 Rule-13
; implementation clearance, coherence-lens BLOCKER; FP_SELECT_CLEARANCE.md):
; the chained-theta ALIAS-REBASE evasion of gate 5. `%q1 = cq_theta(%q0, ...)`
; is the sanctioned in-place rebase — after lowering, %q0 and %q1 are ONE
; physical handle — and the `cq_phi` hangs off the OLD alias %q0: a USER of a
; sibling SSA name, in neither the select operand's backward operand DAG nor
; its forward user DAG. The pre-fix SSA-anchored gate-5 walks missed it and the
; merge CNOT-copied a PHASED wire (rz then copy on the same handle — the exact
; circuit control_swap_reject_select_fp_phase_operand.ll declines, differing
; only in SSA spelling; the WI-3 dephasing family, verify-clean). The fixed
; gate 5 walks PHYSICAL WIRES: rotation-call users (arg-0) are wire
; continuations, so the sibling Rz is found and the select declines.
;
;
; ===========================================================================
; 3qlq(prep_a2): HAND DECISION — RE-SPELLED. The ALIAS-REBASE evasion is a
; statement about SSA ANCHORING, not about phases: `%q1 = cq_theta(%q0, ...)` is
; a rebase that gives the SAME physical handle a NEW SSA name, so a gate-5 walk
; anchored on the SSA value the select names misses a rotation written against
; the OLD name. The original spelled the sibling gate as an Rz (`cq_phi`) because
; a DIAGONAL gate made the "same wire, different name" story cleanest; the
; anchoring hole itself never needed diagonality, and the rebase — the thing
; being evaded — is a `cq_theta` in both versions.
;
; RE-SPELLING: the select names `%q0` (the OLD alias) while the rebase `%q1` is
; the live handle, so the operand's wire is rotated under a different SSA name.
; MEASURED on `build/ir-pass/cq-opt`: exit 1, the same string this file always
; asserted ($SP/progress/prep_a2_work/pv/alias.ll).
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: control flow under quantum control

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @example(double %u0, double %v0, double %x) {
entry:
  %q0  = call double @cq_theta_f64(double %u0, double 1.000000e+00)
  %q1  = call double @cq_theta_f64(double %q0, double 5.000000e-01) ; rebase
  %y   = call double @cq_theta_f64(double %v0, double 2.500000e-01)
  %c   = fcmp ogt double %y, 5.000000e-01
  %sel = select i1 %c, double %q0, double %x   ; names the OLD alias of a live wire
  %m   = call double @cq_measure_f64(double %sel)
  %m2  = call double @cq_measure_f64(double %q1)
  ret double %m
}
