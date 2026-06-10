; lowering_reject_tainted_angle_opaque.ll — DECLINE: quantum-derived rotation
; ANGLE in STRAIGHT-LINE code, opaque-call family.
;
; `%ang = call double @ext(i32 %q)` is TAINTED (any non-angle user of a tainted
; value is) and feeds `cq_phi`'s arg-1 ANGLE slot. Unlike the cast family this
; one survives WELL-TYPED: nothing lowers an opaque call, so after rotation
; lowering's RAUW (%q → i32 runtime handle) the surviving `@ext` call reads the
; RUNTIME HANDLE TAG — verify-clean, links, runs, prints a plausible trace with
; a fixed angle = f(handle_tag): the silent-miscompile class, in straight-line
; code (found by the test_C_libtooling-9hh §8 adversarial clearance, tracked as
; test_C_libtooling-659). Reachable from real C:
; `double t = f(q); q = cq_phi(q, t);` — no control flow at all.
;
; The region-level guard (ArmClassify::taintedAngleGate) never runs here; the
; straight-line guard in RotationLowering::lowerRotations must decline loudly
; BEFORE any emission.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare double @ext(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %ang = call double @ext(i32 %q)                 ; TAINTED angle producer
  %qd = call i32 @cq_phi_si32(i32 %q, double %ang)
  %m = call i32 @cq_measure_si32(i32 %qd)
  ret i32 %m
}

; CHECK: error{{.*}}cq rotation lowering: unsupported quantum-derived rotation angle
