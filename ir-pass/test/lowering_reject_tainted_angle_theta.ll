; lowering_reject_tainted_angle_theta.ll — DECLINE: quantum-derived ANGLE on a
; `cq_theta` (Ry), straight-line. Mirrors the cq_phi guard on the theta path.
;
; `%ang = sitofp i32 %q to double` is TAINTED and feeds the SECOND theta's
; arg-1 ANGLE slot. Without the guard the lowering mints a fresh handle for the
; classical operand `%u1` and emits `cqrt_ry(h2, %ang)` with a quantum-derived
; angle: an Ry by a function of a value in superposition has no fixed unitary;
; decline loudly, lower nothing (test_C_libtooling-659).
;
; PRODUCER CHOICE (test_C_libtooling-bxv re-shape): the original opaque-call
; producer (`%ang = call double @ext(i32 %q)`) now declines EARLIER at the
; module-wide taint-escape guard — @ext consuming the handle is an escape in
; its own right, pinned by lowering_reject_taint_escape_opaque_call.ll — and
; opt exits at the first error diagnostic. A sitofp producer is NOT an escape
; (casts are lowerOps' class), so this fixture keeps pointing at the
; THETA-slot path of RotationLowering::declineTaintedAngle it exists to pin.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %ang = sitofp i32 %q to double                  ; TAINTED angle producer
  %q2 = call i32 @cq_theta_si32(i32 %u1, double %ang)
  %m = call i32 @cq_measure_si32(i32 %q2)
  ret i32 %m
}

; CHECK: error{{.*}}cq rotation lowering: unsupported quantum-derived rotation angle
