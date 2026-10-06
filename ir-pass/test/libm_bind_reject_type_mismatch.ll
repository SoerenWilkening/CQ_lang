; libm_bind_reject_type_mismatch.ll — bd 3c6m.72: `@llvm.frexp.f64.i32` returns
; an aggregate while libm `frexp` writes through a pointer, so the injected
; `__cq_libm_frexp` does not have the call's function type and the binding
; refuses it (LibmBinding.h): the call stays an unknown callee, loudly. Retire
; this decline when an aggregate-return frexp route is built (goal 1).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq taint escape: tainted value consumed by an unknown callee
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare { double, i32 } @llvm.frexp.f64.i32(double)

define double @__cq_libm_frexp(double %x, ptr %e) {
  store i32 0, ptr %e
  ret double %x
}

define double @example(double %u0) {
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %fr = call { double, i32 } @llvm.frexp.f64.i32(double %q)
  %s = extractvalue { double, i32 } %fr, 0
  %m = call double @cq_measure_f64(double %s)
  ret double %m
}
