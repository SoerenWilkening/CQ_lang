; lowering_reject_select_fp_backstop_arith.ll — DECLINE (fp-data-select-PRD §5
; matrix 2a, the LEG-3 BACKSTOP): an ACCEPTED fp-data select whose result is
; re-realized through fp ARITHMETIC (`fadd` — value-changing, deliberately NOT a
; gate-3 carrier) and lands in a rotation arg-1. Gate 3 does not cross `fadd`,
; so detection accepts and `SelectMergeEmit` EMITS the merge (RAUW %sel -> %out)
; — this is a documented MUTATE-THEN-DECLINE (the 6.5 post-hoist precedent):
; `opt` still exits non-zero because `declineTaintedAngle`
; (RotationLowering.cpp) fires on the re-realized tainted angle. The two §2
; leg-3 invariants make this backstop sighted: SelectMergeEmit inserts %out into
; taint.Tainted (derived users stay tainted) and scrubTaint erases ONLY the
; SelectInst — so `%ang = fadd %out, 0.1` is still tainted at lowerRotations.
;
; The leading CHECK-NOT pins that NO control-dialect decline fired first — the
; decline is the BACKSTOP's, proving the division of labor (gate 3 owns
; carriers; leg 3 owns value-changing re-realizations).
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
  %sel = select i1 %c, double %q, double %x               ; ACCEPTED fp-data select
  %ang = fadd double %sel, 1.000000e-01                   ; value-CHANGING re-realization
  %q2  = call double @cq_phi_f64(double %p, double %ang)  ; tainted ANGLE -> leg-3 backstop
  %m   = call double @cq_measure_f64(double %q2)
  ret double %m
}
