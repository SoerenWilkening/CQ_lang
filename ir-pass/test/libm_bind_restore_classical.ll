; libm_bind_restore_classical.ll — bd 3c6m.72, review round 1: a call that
; still targets a PUBLIC bundle body at the end of the pass (bound, then its
; operand's taint folded away; written directly here) is classical, so it goes
; back to the system libm and the body is erased. Classical code never runs
; injected source (owner ruling 2026-10-06).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=GONE < %t.ll
; CHECK:     define double @example(double %u0, double %c)
; CHECK:     call double @cbrt(double %c)
; CHECK:     declare double @cbrt(double)
; GONE-NOT:  @__cq_libm_cbrt
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @__cq_libm_cbrt(double %x) {
  %y = fadd double %x, 2.000000e+00
  ret double %y
}

define double @example(double %u0, double %c) {
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %m = call double @cq_measure_f64(double %q)
  %k = call double @__cq_libm_cbrt(double %c)
  %z = fadd double %m, %k
  ret double %z
}
