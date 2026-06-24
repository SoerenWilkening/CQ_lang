; lowering_reject_math_result_as_angle_sin.ll — DECLINE: a TAINTED, NOW-RECOGNIZED
; math result (`@llvm.sin.f64(q)`) reaching a rotation's arg-1 ANGLE slot
; (PRD-iw81.4 §7 hazard 1, decline-matrix D1). This CLOSES THE PROXY GAP that
; iw81.4.a could only pin with a tainted `fmul` proxy: now that sin is a curated
; fp-DATA producer (iw81.4.b), this fixture exercises the REAL headline shape —
; `cq_phi(u, sin(q))` — and proves it STILL loud-declines, never lowering a soft-
; float quantum-derived ANGLE through the new `cq_template_sin_f64` DATA template
; (the f64 angle/data silent-miscompile family). See bd
; [fp-angle-fence-ordering-invariant], mandatory follow-up (3).
;
; WHY IT HOLDS (verified empirically this session): `lowerRotations`
; (RotationLowering::declineTaintedAngle) runs BEFORE `lowerOps`
; (CQLoweringPass.cpp:177 vs :178), and sin recognition/lowering (rewriteIntrinsic)
; lives in `lowerOps`. The fence keys on `taint.Tainted.count(arg-1)`
; (producer-agnostic): the per-use arg-1 skip excludes ONLY the `cq_phi` angle
; EDGE, never the sin producer's own taint — so `%s` is in `Tainted` and the fence
; fires while `@llvm.sin.f64` is STILL its source call. NOT one fp template is minted.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare double @cq_theta_f64(double, double)
declare double @cq_phi_f64(double, double)
declare double @cq_measure_f64(double)
declare double @llvm.sin.f64(double)

define double @example(double %u0) {
entry:
  %q   = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %s   = call double @llvm.sin.f64(double %q)             ; TAINTED, recognized fp-DATA
  %qd  = call double @cq_phi_f64(double %u0, double %s)   ; %s in the arg-1 ANGLE slot
  %m   = call double @cq_measure_f64(double %qd)
  ret double %m
}

; CHECK: error{{.*}}cq rotation lowering: unsupported quantum-derived rotation angle
; Declined inside lowerRotations, BEFORE lowerOps — so the sin template is never minted:
; CHECK-NOT: cq_template_sin
; CHECK-NOT: cqrt_rz
