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
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
; CHECK-NOT: cqrt_copy
declare double @cq_theta_f64(double, double)
declare double @cq_phi_f64(double, double)
declare double @cq_measure_f64(double)

define double @example(double %u0, double %x) {
entry:
  %q0  = call double @cq_theta_f64(double %u0, double 1.000000e+00)
  %p   = call double @cq_phi_f64(double %q0, double 7.000000e-01)   ; Rz on the OLD alias — same wire
  %q1  = call double @cq_theta_f64(double %q0, double 5.000000e-01) ; rebase: new SSA name, same handle
  %c   = fcmp ogt double %q1, 5.000000e-01
  %sel = select i1 %c, double %q1, double %x                        ; operand's WIRE carries the phase
  %m   = call double @cq_measure_f64(double %sel)
  %m2  = call double @cq_measure_f64(double %p)
  ret double %m
}
