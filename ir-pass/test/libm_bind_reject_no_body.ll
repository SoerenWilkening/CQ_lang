; libm_bind_reject_no_body.ll — bd 3c6m.72: with no injected `__cq_libm_exp`
; in the module (a pipeline that did not link the bundle), a tainted
; `@llvm.exp.f64` binds to nothing and stays an unknown callee: loud, never
; lowered by name (LibmBinding.h).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq taint escape: tainted value consumed by an unknown callee
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare double @llvm.exp.f64(double)

define double @example(double %u0) {
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %s = call double @llvm.exp.f64(double %q)
  %m = call double @cq_measure_f64(double %s)
  ret double %m
}
