; lowering_reject_frozen_wire_phi.ll — DECLINE (test_C_libtooling-4i7r): a
; tainted fp `freeze` of a quantum WIRE. Pre-3qlq it fed a register-form
; `cq_phi` (Rz) arg-0 handle slot, and PRE-FIX that SIGABRT'd (134) — the theta
; RAUW-to-i32-handle left `freeze double %h` ill-typed and `cqrt_rz_f64(double %f,
; …)` read the fp freeze in an i32 slot. The migration deleted that uncontrolled
; phase, so the freeze is now dead; the `declineFrozenWire` scan still declines
; the tainted non-i32 freeze BEFORE the RAUW.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq rotation lowering: unsupported frozen quantum wire
; CHECK-NOT: Broken module
; CHECK-NOT: does not match function signature
; CHECK-NOT: cqrt_rz_f64(double
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2))
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @example(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %f = freeze double %q                           ; frozen quantum wire
  %m = call double @cq_measure_f64(double %q)      ; main wire measured (dead sibling above)
  ret double %m
}
