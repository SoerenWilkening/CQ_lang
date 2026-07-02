; lowering_reject_select_fp_backstop_domaincast.ll — DECLINE (fp-data-select-PRD
; §5 matrix 2b, the LEG-3 BACKSTOP): an ACCEPTED fp-data select whose result is
; re-realized through an int<->fp DOMAIN-CAST chain (`fptoui`/`uitofp` — value-
; changing, deliberately NOT gate-3 carriers; only the value-preserving
; fpext/fptrunc/bitcast/freeze/phi/nested-select are crossed) and lands in a
; rotation arg-1. Detection accepts, the merge is EMITTED (mutate-then-decline,
; the 6.5 post-hoist precedent), and `declineTaintedAngle` still exits `opt`
; non-zero: the domain casts are tainted users of the tainted %out (the §2
; leg-3 invariants — Tainted.insert(%out), scrubTaint erases only the select).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK-NOT: under quantum control
; CHECK: error{{.*}}cq rotation lowering: unsupported quantum-derived rotation angle
declare double @cq_theta_f64(double, double)
declare double @cq_phi_f64(double, double)
declare double @cq_measure_f64(double)

define double @example(double %u0, double %u1, double %x) {
entry:
  %q   = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %p   = call double @cq_theta_f64(double %u1, double 5.000000e-01)
  %c   = fcmp ogt double %q, 5.000000e-01
  %sel = select i1 %c, double %q, double %x             ; ACCEPTED fp-data select
  %i   = fptoui double %sel to i32                      ; value-CHANGING domain cast
  %f   = uitofp i32 %i to double                        ; re-realized fp value
  %q2  = call double @cq_phi_f64(double %p, double %f)  ; tainted ANGLE -> leg-3 backstop
  %m   = call double @cq_measure_f64(double %q2)
  ret double %m
}
