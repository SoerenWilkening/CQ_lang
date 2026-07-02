; control_swap_reject_select_fp_coherent.ll — DECLINE (fp-data-select-PRD §5
; matrix 4): an fp select operand FEEDING a downstream rotation on its wire
; (arg-0) beyond the select — channel B of the §16.7 coherent-operand default.
; The rotation's interference would observe the operand's coherence, which the
; basis CNOT copy breaks. Gate 5 (`hasCoherentDownstreamUse`, the forward walk)
; fires — type-agnostic, unchanged by the gate-4 fp un-staging.
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
  %c   = fcmp ogt double %q, 5.000000e+00
  %sel = select i1 %c, double %q, double %x
  %qd  = call double @cq_phi_f64(double %q, double 3.000000e-01)  ; rotation ON %q's wire AFTER the select
  %ms  = call double @cq_measure_f64(double %sel)
  %md  = call double @cq_measure_f64(double %qd)
  ret double %ms
}
