; lowering_reject_fma_llq_result_as_angle.ll — DECLINE (bd 3c6m.73 adversarial
; probe): the new `llq` fma shape (classical product, quantum addend) is a tainted
; fp-DATA producer like every other fma shape. Its result in the angle operand of a
; rotation must still fail loudly (R3: the angle is classical today; a quantum angle
; is the open gap bd 94ad, never an ad-hoc qubit for the f64). Mirrors
; lowering_reject_fma_result_as_angle.ll for the shape whose product pair carries no
; handle at all, so taint reaches the angle ONLY through the addend.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare void @cq_phi(double)
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare double @llvm.fma.f64(double, double, double)

define double @example(double %u, double %x, double %y) {
entry:
  %q   = call double @cq_theta_f64(double %u, double 5.000000e-01)
  %fma = call double @llvm.fma.f64(double %x, double %y, double %q)
  call void @cq_phi(double %fma)
  %m   = call double @cq_measure_f64(double %q)
  ret double %m
}

; CHECK: error{{.*}}cq rotation lowering: unsupported quantum-derived rotation angle
; (R10, 2026-10-08: the CHECK-NOT lines that followed the error were removed as vacuous —
; opt exits on the first DS_Error and prints no IR, so nothing can follow it.)
