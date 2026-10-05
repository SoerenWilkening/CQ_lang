; lowering_reject_fma_result_as_angle.ll — DECLINE: a TAINTED, NOW-RECOGNIZED
; ternary fma result (`@llvm.fma.f64(q, r, s)`) used as a rotation ANGLE
; (PRD-iw81.4 §7 hazard 1 / decline-matrix D1, the wd2p ternary counterpart
; of lowering_reject_math_result_as_angle.ll's `fmul` proxy). The recognized
; unary sibling this once cited, lowering_reject_math_result_as_angle_sin.ll, was
; deleted at ce069c64 (libm name-recognition retired); no fixture now puts a
; recognized unary math intrinsic in the angle operand. Now that fma is a curated
; fp-DATA producer, `cq_phi(fma(q,r,s))` puts the tainted fma result in the
; phase's one (angle) operand and MUST STILL loud-decline — never lowering a
; quantum-derived ANGLE through the `cq_template_fma_f64` DATA template (the
; f64 angle/data silent-miscompile family). See bd [fp-angle-fence-ordering-invariant].
;
; WHY IT HOLDS: the fma result is ordinary tainted data (fp-DATA producer). The
; fence is `deleteGlobalPhases` (TaintPropagation), which declines a surviving
; `cq_phi` whose angle is tainted and runs BEFORE `lowerOps` (where
; rewriteIntrinsic lives), so it fires while `@llvm.fma.f64` is STILL its source
; call. NOT one fma template is minted.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare double @llvm.fma.f64(double, double, double)

define double @example(double %u0, double %v, double %w) {
entry:
  %q   = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %r   = call double @cq_theta_f64(double %v, double 2.500000e-01)
  %s   = call double @cq_theta_f64(double %w, double 1.250000e-01)
  %fma = call double @llvm.fma.f64(double %q, double %r, double %s)   ; TAINTED, recognized fp-DATA
  call void @cq_phi(double %fma)  ; %fma in the arg-0 (sole) ANGLE operand
  %m   = call double @cq_measure_f64(double %u0)
  ret double %m
}

; CHECK: error{{.*}}cq rotation lowering: unsupported quantum-derived rotation angle
; Declined by deleteGlobalPhases, BEFORE lowerOps — so the fma template is never minted:
; CHECK-NOT: cq_template_fma
; CHECK-NOT: cqrt_rz
