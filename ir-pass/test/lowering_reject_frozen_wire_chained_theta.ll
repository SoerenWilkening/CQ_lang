; lowering_reject_frozen_wire_chained_theta.ll — DECLINE (test_C_libtooling-4i7r):
; a tainted fp `freeze` of a quantum WIRE feeding a CHAINED `cq_theta` (arg-0
; handle slot). PRE-FIX this SIGABRT'd (134, "Broken module found") instead of
; declining — a crash on VALID input (Rule 1).
;
; The runtime handle is ALWAYS i32 (Rule 15): `lowerRotations` RAUWs the source
; `%q` (an fp theta result) to an i32 handle `%h`, but a `freeze` is NEVER
; erased (`declineTaintEscapes` SKIPS an fp freeze so it can ride the GATE-3
; angle fence; it is never folded). So `%f = freeze double %q` becomes
; `freeze double <i32 handle>` — ill-typed — and the chained `cqrt_ry_f64` reads
; the fp `%f` in its i32 handle slot; with the wire measured elsewhere (a dead
; sibling), NOTHING owns/declines it and the verifier ABORTS
; ("Call parameter type does not match function signature"). The
; `declineFrozenWire` scan declines every tainted non-i32 freeze BEFORE the
; RAUW, so the freeze stays well-typed and `opt` exits with the house
; diagnostic. Over-decline is safe (Prime Directive); there is no correct
; lowering of a frozen qubit handle under the i32-handle discipline.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq rotation lowering: unsupported frozen quantum wire
; CHECK-NOT: Broken module
; CHECK-NOT: does not match function signature
; CHECK-NOT: cqrt_ry_f64(double
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @example(double %u0) {
entry:
  %q  = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %f  = freeze double %q                          ; frozen quantum wire — un-launderable
  %q2 = call double @cq_theta_f64(double %f, double 3.000000e-01)  ; chained Ry on the frozen wire
  %m  = call double @cq_measure_f64(double %q)     ; main wire measured (dead sibling above)
  ret double %m
}
