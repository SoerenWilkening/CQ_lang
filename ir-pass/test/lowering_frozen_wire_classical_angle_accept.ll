; lowering_frozen_wire_classical_angle_accept.ll — ACCEPT boundary
; (test_C_libtooling-4i7r): the `declineFrozenWire` guard is TAINT-GATED. A
; CLASSICAL fp `freeze` (untainted — freeze of a classical angle argument) is
; NOT a quantum wire and lowers cleanly: it survives verbatim as the classical
; angle operand of `cqrt_rz_f64`, whose i32 handle slot is the (unrelated) theta
; wire. Pins that the guard declines ONLY tainted non-i32 freezes and never
; over-declines the poison-freeze clang inserts around a classical angle
; computation (Rule 12 accept boundary for the decline predicate).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
declare double @cq_theta_f64(double, double)
declare double @cq_phi_f64(double, double)
declare double @cq_measure_f64(double)

define double @example(double %u0, double %ang) {
entry:
  %q  = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %af = freeze double %ang                         ; CLASSICAL freeze (untainted angle)
  %p  = call double @cq_phi_f64(double %q, double %af)  ; classical angle in arg-1
  %m  = call double @cq_measure_f64(double %p)
  ret double %m
}

; The theta mints the i32 handle, the Rz reads the classical frozen angle in
; arg-1, and the freeze is left standing (a classical, well-typed value):
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double %u0)
; CHECK:     call void @cqrt_ry_f64(i32 %[[H]], double 5.000000e-01)
; CHECK:     %[[AF:[a-zA-Z0-9_.]+]] = freeze double %ang
; CHECK:     call void @cqrt_rz_f64(i32 %[[H]], double %[[AF]])
; CHECK:     call double @cqrt_measure_f64(i32 %[[H]])
; CHECK-NOT: frozen quantum wire
