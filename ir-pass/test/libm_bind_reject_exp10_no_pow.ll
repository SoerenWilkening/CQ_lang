; libm_bind_reject_exp10_no_pow.ll — DECLINE (bd test_C_libtooling-3c6m.81).
; The exp10 -> pow binding needs the injected `pow` body. Without it (a pipeline
; that did not link the bundle), a tainted `@llvm.exp10.f64` binds nothing and
; stays an unknown callee: loud, never lowered by name.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq taint escape: tainted value consumed by an unknown callee
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare double @llvm.exp10.f64(double)

define double @example(double %u0) {
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %s = call double @llvm.exp10.f64(double %q)
  %m = call double @cq_measure_f64(double %s)
  ret double %m
}
