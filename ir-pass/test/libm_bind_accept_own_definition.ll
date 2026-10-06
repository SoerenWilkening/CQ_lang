; libm_bind_accept_own_definition.ll — bd 3c6m.72, review round 1 finding 4: a
; program that defines `sin` itself gets that body for a quantum `llvm.sin.f64`
; call, because its classical twin reaches the program's `sin` at link time
; (CLAUDE R14: the injected source is the program's). The bundle body is not
; used and is erased.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=GONE < %t.ll
; CHECK:     define double @example(double %u0)
; CHECK:     call i32 @__cq_q_sin_1(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     define internal i32 @__cq_q_sin_1(i32 %x)
; CHECK:     cq_template_fadd_f64_hl(i32 %x, double 3.000000e+00)
; GONE-NOT:  @__cq_libm_sin
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare double @llvm.sin.f64(double)

define double @sin(double %x) {
  %y = fadd double %x, 3.000000e+00
  ret double %y
}
define double @__cq_libm_sin(double %x) {
  %y = fmul double %x, 2.000000e+00
  ret double %y
}

define double @example(double %u0) {
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %s = call double @llvm.sin.f64(double %q)
  %m = call double @cq_measure_f64(double %s)
  ret double %m
}
