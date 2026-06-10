; lowering_reject_tainted_angle_theta.ll — DECLINE: quantum-derived ANGLE on a
; `cq_theta` (Ry), straight-line. Mirrors the cq_phi guard on the theta path.
;
; `%ang = call double @ext(i32 %q)` is TAINTED and feeds the SECOND theta's
; arg-1 ANGLE slot. Without the guard the lowering mints a fresh handle for the
; classical operand `%u1` and emits `cqrt_ry(h2, %ang)` where, after the first
; theta's RAUW, `%ang = ext(handle_tag)` — verify-clean, links, runs, prints a
; plausible trace with a fixed angle = f(handle_tag): the same straight-line
; silent-miscompile class as the cq_phi opaque-call family (test_C_libtooling-659).
; An Ry by a quantum-derived angle has no fixed unitary; decline loudly,
; lower nothing.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare double @ext(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %ang = call double @ext(i32 %q)                 ; TAINTED angle producer
  %q2 = call i32 @cq_theta_si32(i32 %u1, double %ang)
  %m = call i32 @cq_measure_si32(i32 %q2)
  ret i32 %m
}

; CHECK: error{{.*}}cq rotation lowering: unsupported quantum-derived rotation angle
