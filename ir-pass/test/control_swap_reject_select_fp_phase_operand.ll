; control_swap_reject_select_fp_phase_operand.ll — DECLINE (fp-data-select-PRD
; §5 matrix 3): an fp select OPERAND carrying an Rz (`cq_phi`) in its lineage —
; a relative-PHASE carrier. The controlled-XOR merge is a CNOT basis copy: it
; copies a basis LABEL, not a phase (Rule 7), so lowering this would dephase the
; answer (the 0.585->0.500 WI-3 family, verify-clean-invisible). Gate 5
; (`operandCarriesPhase`, the backward lineage walk) fires — the fp un-staging
; touches only gate 4's TYPE fence; the coherence gates are type-agnostic and
; keep fp phase carriers out of the merge.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
; CHECK-NOT: cqrt_copy
declare double @cq_theta_f64(double, double)
declare double @cq_phi_f64(double, double)
declare double @cq_measure_f64(double)

define double @example(double %u0, double %x) {
entry:
  %q   = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %qd  = call double @cq_phi_f64(double %q, double 3.000000e-01)  ; Rz — PHASE carrier
  %c   = fcmp ogt double %qd, 5.000000e+00
  %sel = select i1 %c, double %qd, double %x       ; phase-carrying fp operand
  %m   = call double @cq_measure_f64(double %sel)
  ret double %m
}
