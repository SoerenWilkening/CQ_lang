; control_swap_reject_select_stalecond_chained_theta.ll — DECLINE (kjd1 Rule-13
; implementation clearance, fcmp-lens BLOCKER; FP_SELECT_CLEARANCE.md): a
; chained cq_theta (an IN-PLACE, NON-DIAGONAL Ry on the condition's wire —
; RotationLowering lowers a tainted-operand theta to `ry` on the EXISTING
; handle) sits between the source fcmp and the select. SelectMergeEmit mints
; the flag AT THE SELECT, so without a guard the emitted flag encodes
; fcmp(post-Ry basis) while the SSA condition denotes the pre-Ry record — the
; copies then route %out on the wrong predicate: a verify-clean wrong unitary
; (the strip still cleans the flag, so nothing LOOKS wrong). Empirically
; reproduced pre-fix (probe p11: ry(0.5); ry(0.7); fcmp mint; copies; exit 0).
;
; The guard is the select mirror of ArmClassify's condWireDisposition (named
; nonDiagonalGateBeforeBranch until bd lom0 Inc 4)
; (same string, same WireWalk position-free provenance walk + the positional
; compare->select tainted-theta scan; Rule 14). Both sibling classifiers
; (br-diamond, switch) already had it; 4.4 shipped without it and the hole
; became fp-reachable through the kjd1 GATE-4 un-staging.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}condition predates a non-diagonal gate under quantum control
; CHECK-NOT: cqrt_copy
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define void @example(double %u0, double %x) {
entry:
  %q   = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %t   = fadd double %q, 1.000000e+00                              ; derived data operand
  %c   = fcmp ogt double %q, 5.000000e-01                          ; SOURCE record: pre-Ry(0.7)
  %q2  = call double @cq_theta_f64(double %q, double 7.000000e-01) ; chained theta: in-place Ry on q's wire
  %sel = select i1 %c, double %t, double %x                        ; flag would mint POST-Ry here
  %m1  = call double @cq_measure_f64(double %sel)
  %m2  = call double @cq_measure_f64(double %q2)
  ret void
}
