; lowering_reject_fma_result_as_angle.ll — DECLINE: a TAINTED, NOW-RECOGNIZED
; ternary fma result (`@llvm.fma.f64(q, r, s)`) reaching a rotation's arg-1 ANGLE
; slot (PRD-iw81.4 §7 hazard 1 / decline-matrix D1, the wd2p ternary counterpart
; of lowering_reject_math_result_as_angle_sin.ll). Now that fma is a curated
; fp-DATA producer, `cq_phi(u, fma(q,r,s))` puts the tainted fma result in the
; arg-1 slot and MUST STILL loud-decline — never lowering a soft-float
; quantum-derived ANGLE through the new `cq_template_fma_f64` DATA template (the
; f64 angle/data silent-miscompile family). See bd [fp-angle-fence-ordering-invariant].
;
; WHY IT HOLDS: `lowerRotations` (RotationLowering::declineTaintedAngle) runs
; BEFORE `lowerOps` (where rewriteIntrinsic lives), and the fence keys on
; `taint.Tainted.count(arg-1)` (producer-agnostic). The per-use arg-1 skip
; (TaintPropagation.cpp:303) excludes ONLY the `cq_phi` angle EDGE, never the fma
; producer's own taint — so the fma result is in `Tainted` and the fence fires
; while `@llvm.fma.f64` is STILL its source call. NOT one fma template is minted.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare double @cq_theta_f64(double, double)
declare double @cq_phi_f64(double, double)
declare double @cq_measure_f64(double)
declare double @llvm.fma.f64(double, double, double)

define double @example(double %u0, double %v, double %w) {
entry:
  %q   = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %r   = call double @cq_theta_f64(double %v, double 2.500000e-01)
  %s   = call double @cq_theta_f64(double %w, double 1.250000e-01)
  %fma = call double @llvm.fma.f64(double %q, double %r, double %s)   ; TAINTED, recognized fp-DATA
  %qd  = call double @cq_phi_f64(double %u0, double %fma)             ; %fma in the arg-1 ANGLE slot
  %m   = call double @cq_measure_f64(double %qd)
  ret double %m
}

; CHECK: error{{.*}}cq rotation lowering: unsupported quantum-derived rotation angle
; Declined inside lowerRotations, BEFORE lowerOps — so the fma template is never minted:
; CHECK-NOT: cq_template_fma
; CHECK-NOT: cqrt_rz
