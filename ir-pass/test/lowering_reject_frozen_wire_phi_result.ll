; lowering_reject_frozen_wire_phi_result.ll — DECLINE (test_C_libtooling-4i7r,
; adversarial variant): the frozen wire is a `cq_phi` (Rz) RESULT, not a source
; `cq_theta` result. Pins that `declineFrozenWire` catches a freeze of ANY
; rotation wire (the phi's result is RAUW'd to the same i32 handle as the theta
; it chains from), not just a source-theta freeze — the scan keys on the freeze
; being tainted + non-i32, independent of which rotation produced the wire.
;
; Ordering hazard this pins: the chained `%q2` (reading the frozen `%p`) is
; processed in the THETA loop, which runs before the PHI loop — so a guard that
; only inspected each rotation's own result-users would emit the mistyped
; `cqrt_ry` before the phi's guard fired. The pre-loop module scan closes that.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq rotation lowering: unsupported frozen quantum wire
; CHECK-NOT: Broken module
; CHECK-NOT: does not match function signature
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2))
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @example(double %u0) {
entry:
  %q  = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %f  = freeze double %q                          ; freeze the PHI result wire
  %q2 = call double @cq_theta_f64(double %f, double 2.000000e-01) ; chained on the frozen wire
  %m  = call double @cq_measure_f64(double %q)     ; the phi wire is measured (dead sibling above)
  ret double %m
}
