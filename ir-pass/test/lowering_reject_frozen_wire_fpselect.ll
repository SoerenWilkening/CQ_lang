; lowering_reject_frozen_wire_fpselect.ll — DECLINE (test_C_libtooling-4i7r,
; adversarial variant): the frozen wire is the RESULT of an ACCEPTED fp-data
; `select` (kjd1 controlled-XOR copy merge), consumed by a sibling `cq_phi`
; while the select result is measured. `lowerControlRegions` (SwapRouteEmit) —
; which runs BEFORE `lowerRotations` — RAUWs the select result to an i32 merge
; handle, so `%f = freeze double %sel` is ALREADY ill-typed by the time rotation
; lowering runs, and the sibling `cqrt_rz` reads the fp freeze in an i32 slot
; (pre-fix SIGABRT). Pins that `declineFrozenWire`, running at the top of
; `lowerRotations`, catches a wire frozen from a NON-rotation producer (the
; select) too — the guard is placed after every wire-minting stage and before
; the first rotation RAUW.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq rotation lowering: unsupported frozen quantum wire
; CHECK-NOT: Broken module
; CHECK-NOT: does not match function signature
declare double @cq_theta_f64(double, double)
declare double @cq_phi_f64(double, double)
declare double @cq_measure_f64(double)

define double @example(double %u, double %v) {
entry:
  %q1  = call double @cq_theta_f64(double %u, double 5.000000e-01)
  %q2  = call double @cq_theta_f64(double %v, double 5.000000e-01)
  %c   = fcmp ogt double %q1, 5.000000e-01
  %sel = select i1 %c, double %q1, double %q2     ; accepted fp-data select (kjd1)
  %f   = freeze double %sel                        ; freeze the merged wire
  %p   = call double @cq_phi_f64(double %f, double 3.000000e-01)  ; Rz on the frozen merge wire
  %m   = call double @cq_measure_f64(double %sel)  ; merge wire measured (dead sibling above)
  ret double %m
}
