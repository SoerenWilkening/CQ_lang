; lowering_frozen_wire_classical_angle_accept.ll — ACCEPT boundary
; (test_C_libtooling-4i7r): the `declineFrozenWire` guard is TAINT-GATED. A
; CLASSICAL fp `freeze` (untainted — freeze of a classical angle argument) is
; NOT a quantum wire and lowers cleanly: it survives verbatim as the classical
; angle operand of `cqrt_ry_f64`, whose i32 handle slot is the (unrelated) theta
; wire. Pins that the guard declines ONLY tainted non-i32 freezes and never
; over-declines the poison-freeze clang inserts around a classical angle
; computation (Rule 12 accept boundary for the decline predicate).
;
;     double example(double u0, double ang) {
;       double q = u0; cq_theta(&q, 0.5);
;       cq_theta(&q, ang);              /* the angle reaches the gate frozen */
;       return cq_measure(q);
;     }
;
; Hand IR: the `freeze` on the angle is placed by hand (as in the decline twins
; of this guard); plain `clang -O1` of the C above passes `%ang` unfrozen.
;
; History: pre-3qlq the frozen angle fed a register-form `%p = cq_phi(%q, %af)`
; (an in-place Rz, `cqrt_rz_f64(%h, %af)`). The 3qlq migration deleted that
; uncontrolled phase and left the freeze with no rotation to feed; bd jttf
; (2026-10-05) re-spelled the consumer as the in-place Ry above, so the frozen
; classical value is again a rotation's angle operand.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=SILENT --allow-empty < %t.err
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2)); jttf: re-spelled register-free 2026-10-05
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @example(double %u0, double %ang) {
entry:
  %q  = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %af = freeze double %ang                                ; CLASSICAL freeze (untainted angle)
  %p  = call double @cq_theta_f64(double %q, double %af)  ; classical angle in arg-1
  %m  = call double @cq_measure_f64(double %p)
  ret double %m
}

; The theta mints the i32 handle, the chained Ry reads the classical frozen
; angle in arg-1 on the SAME handle, and the freeze is left standing (a
; classical, well-typed value):
; CHECK-LABEL: define double @example(
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double %u0)
; CHECK-NEXT: call void @cqrt_ry_f64(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[AF:[a-zA-Z0-9_.]+]] = freeze double %ang
; CHECK-NEXT: call void @cqrt_ry_f64(i32 %[[H]], double %[[AF]])
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call double @cqrt_measure_f64(i32 %[[H]])
; CHECK-NEXT: ret double %[[M]]
; and the guard is silent (exit 0 alone would not show that a warning-class
; message was not printed):
; SILENT-NOT: frozen quantum wire
; SILENT-NOT: error
