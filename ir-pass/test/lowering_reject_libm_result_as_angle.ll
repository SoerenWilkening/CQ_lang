; lowering_reject_libm_result_as_angle.ll — DECLINE: a TAINTED, NOW-RECOGNIZED
; DIRECT-libm result (`@cbrt(q)`) reaching a rotation's arg-1 ANGLE slot. The
; headline safety property of bd 3c6m.2: curating a libm name only ADDS its
; result to `Tainted`, so the fp angle/data fence STILL fires — a quantum-derived
; soft-float angle is NEVER lowered through the new `cq_template_cbrt_f64` DATA
; template (the f64 angle/data silent-miscompile family). Producer-agnostic,
; exactly as for the intrinsic sin (lowering_reject_math_result_as_angle_sin.ll)
; and the fmul proxy — see bd [fp-angle-fence-ordering-invariant].
;
; WHY IT HOLDS: `lowerRotations` (RotationLowering::declineTaintedAngle) runs
; BEFORE `lowerOps` (where LibmLowering recognizes/lowers cbrt). The fence keys on
; `taint.Tainted.count(arg-1)`: `%c` (the cbrt result) is in `Tainted` while
; `@cbrt` is STILL its source call, so the decline fires and NOT ONE libm template
; is minted.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare double @cq_theta_f64(double, double)
declare double @cq_phi_f64(double, double)
declare double @cq_measure_f64(double)
declare double @cbrt(double)

define double @example(double %u0) {
entry:
  %q  = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %c  = call double @cbrt(double %q)                    ; TAINTED, recognized fp-DATA
  %qd = call double @cq_phi_f64(double %u0, double %c)  ; %c in the arg-1 ANGLE slot
  %m  = call double @cq_measure_f64(double %qd)
  ret double %m
}

; CHECK: error{{.*}}cq rotation lowering: unsupported quantum-derived rotation angle
; Declined inside lowerRotations, BEFORE lowerOps — so the libm template is never minted:
; CHECK-NOT: cq_template_cbrt
; CHECK-NOT: cqrt_rz
