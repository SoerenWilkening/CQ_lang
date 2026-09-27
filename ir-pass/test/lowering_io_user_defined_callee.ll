; lowering_io_user_defined_callee.ll — NOT-A-SINK (Phase 7.6, Rule-13 R5): a
; USER-DEFINED in-module function named `printf` (a definition, not the libc
; extern) is NOT the print sink. Both the carve and `isRecognizedIOSink` require
; the callee to be a DECLARATION, so a user's own `printf` body is left to its
; normal owner (here the Phase-6 specializer lifts the pure body) instead of being
; taped — taping it would silently ERASE the user's call. The key 7.6 property:
; ZERO tape symbols are emitted for a user-defined printf.
;
;
; ⚠ bd test_C_libtooling-vsfp round 2: `%p` is now MEASURED. The user's `printf` body is
; side-effect-free and terminating, so an UNUSED call to it is DEAD under the pass's
; liveness predicate and the dead-argument drop's dead-call seeding deletes it (what
; `-O1` does once the body is visible) — which removed this file's subject (no call,
; no clone; the tape CHECK-NOTs passed vacuously, measured). A live result keeps the
; call, the specializer lifts it (the CHECK below), and the no-tape property is asked
; of a module that still calls the user's `printf`.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=LIFT < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @printf(i32 %x) {
  %s = add i32 %x, 7
  ret i32 %s
}

define i32 @main() {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 1.500000e+00)
  %p = call i32 @printf(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %q)
  %mp = call i32 @cq_measure_si32(i32 %p)
  %s = add i32 %m, %mp
  ret i32 %s
}

; The user-defined printf is not taped (no output-tape ABI emitted for it):
; CHECK-NOT: cqrt_tape_alloc
; CHECK-NOT: cqrt_tape_write
; The call is still there, lifted by its normal owner (the Phase-6 specializer) — its own
; prefix, so the default prefix's CHECK-NOTs keep their whole-file window:
; LIFT: call i32 @__cq_q_printf_1(
