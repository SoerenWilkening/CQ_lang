; libm_bind_accept_exp10_as_pow.ll — ACCEPT (bd test_C_libtooling-3c6m.81).
; clang -O1's library-call simplifier rewrites `pow(10.0, x)` to `@llvm.exp10.*`
; (and `pow(10.0f, x)` to the float one). C17 math.h has no `exp10`, so the cqc
; bundle defines none, and a quantum `pow(10.0, q)` failed loudly as an unknown
; callee. The source the user wrote is `pow(10, x)`: the binder now binds an
; `exp10` spelling with no body of its own to the injected `pow` body, with the
; base 10 restored, and the specializer lifts it like any other bound call. A
; classical `exp10` keeps its intrinsic.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK-LABEL: define double @example(
; CHECK:       call {{.*}}@__cq_q___cq_libm_pow_10(double 1.000000e+01, i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:       call double @llvm.exp10.f64(double %c)
; CHECK-LABEL: define float @example_f(
; CHECK:       call {{.*}}@__cq_q___cq_libm_powf_10(float 1.000000e+01, i32 %{{[a-zA-Z0-9_.]+}})
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare float @cq_theta_f32(float, double)
declare float @cq_measure_f32(float)
declare double @llvm.exp10.f64(double)
declare float @llvm.exp10.f32(float)

define double @__cq_libm_pow(double %b, double %x) {
  %y = fmul double %b, %x
  ret double %y
}
define float @__cq_libm_powf(float %b, float %x) {
  %y = fmul float %b, %x
  ret float %y
}

define double @example(double %u0, double %c) {
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %s = call double @llvm.exp10.f64(double %q)
  %m = call double @cq_measure_f64(double %s)
  %k = call double @llvm.exp10.f64(double %c)
  %z = fadd double %m, %k
  ret double %z
}

define float @example_f(float %u0) {
  %q = call float @cq_theta_f32(float %u0, double 5.000000e-01)
  %s = call float @llvm.exp10.f32(float %q)
  %m = call float @cq_measure_f32(float %s)
  ret float %m
}
