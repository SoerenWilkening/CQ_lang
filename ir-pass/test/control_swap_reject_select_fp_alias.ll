; control_swap_reject_select_fp_alias.ll — DECLINE (fp-data-select-PRD §5 matrix
; 7): ALIASING fp operands — two `cq_phi` of ONE base resolve to the SAME
; post-lowering register (the f64 mirror of control_swap_reject_select_alias.ll).
; As in the integer fixture, gate 5 (`operandCarriesPhase`) fires FIRST here
; (both operands carry Rz lineage) with the same `control flow` string; gate 6
; (`operandsAlias`, the diagonal-alias closure) is the structural backstop that
; holds even if the gate-5 coherence boundary is ever widened. Either way the
; fp un-staging must not admit two views of one physical wire into the two-copy
; merge.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
; CHECK-NOT: cqrt_copy
declare double @cq_theta_f64(double, double)
declare double @cq_phi_f64(double, double)
declare double @cq_measure_f64(double)

define double @example(double %u0) {
entry:
  %q   = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %qa  = call double @cq_phi_f64(double %q, double 5.000000e-01)  ; phi of %q
  %qb  = call double @cq_phi_f64(double %q, double 7.000000e-01)  ; ALSO phi of %q — same wire
  %c   = fcmp ogt double %q, 5.000000e+00
  %sel = select i1 %c, double %qa, double %qb    ; both operands alias %q's register
  %m   = call double @cq_measure_f64(double %sel)
  ret double %m
}
