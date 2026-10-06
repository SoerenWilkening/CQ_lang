; libm_bind_accept.ll — bd 3c6m.72: a quantum math.h call reaches the body
; tools/cqc injected (`__cq_libm_<name>`, tools/libm_bundle.py); a classical one
; keeps its callee (owner ruling 2026-10-06: purely classical behaviour must not
; change). LibmBinding.h: a tainted `@llvm.exp.f64` binds to `__cq_libm_exp` and
; a tainted declared `@cbrt` to `__cq_libm_cbrt`, and the specializer lifts each
; like any visible classical callee (no inlining, owner ruling 2026-10-06). A
; curated hardware intrinsic (`sqrt`) keeps its direct template even with a body
; present (R14). Afterwards every bundle object nothing uses is erased, including
; the reference cycle a <-> b and its table, and a helper a lifted copy still
; calls classically (`kc`) survives as internal.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=GONE < %t.ll
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare double @llvm.exp.f64(double)
declare double @llvm.sqrt.f64(double)
declare double @cbrt(double)

define double @__cq_libm_exp(double %x) {
  %k = call double @__cq_libm_kc(double 3.000000e+00)
  %y = fmul double %x, %k
  ret double %y
}
define internal double @__cq_libm_kc(double %c) {
  %r = fadd double %c, 1.000000e+00
  ret double %r
}
define double @__cq_libm_cbrt(double %x) {
  %y = fadd double %x, 2.000000e+00
  ret double %y
}
define double @__cq_libm_sqrt(double %x) {
  %y = fadd double %x, 7.000000e+00
  ret double %y
}
@__cq_libm_tab = global [2 x double] [double 1.0, double 2.0]
define double @__cq_libm_a(double %x) {
  %t = load double, ptr @__cq_libm_tab
  %y = call double @__cq_libm_b(double %t)
  ret double %y
}
define double @__cq_libm_b(double %x) {
  %y = call double @__cq_libm_a(double %x)
  ret double %y
}

define double @example(double %u0, double %c) {
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %s = call double @llvm.exp.f64(double %q)
  %t = call double @cbrt(double %s)
  %w = call double @llvm.sqrt.f64(double %t)
  %m = call double @cq_measure_f64(double %w)
  %k = call double @llvm.exp.f64(double %c)
  %z = fadd double %m, %k
  ret double %z
}

; CHECK:     define internal double @__cq_libm_kc(double %c)
; CHECK:     define double @example(double %u0, double %c)
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double %u0)
; CHECK:     %[[S:[a-zA-Z0-9_.]+]] = call i32 @__cq_q___cq_libm_exp_1(i32 %[[H]])
; CHECK:     %[[T:[a-zA-Z0-9_.]+]] = call i32 @__cq_q___cq_libm_cbrt_1(i32 %[[S]])
; CHECK:     %[[W:[a-zA-Z0-9_.]+]] = call i32 @cq_template_sqrt_f64(i32 %[[T]])
; CHECK:     call double @cqrt_measure_f64(i32 %[[W]])
; CHECK:     call double @llvm.exp.f64(double %c)
; CHECK:     define internal i32 @__cq_q___cq_libm_exp_1(i32 %x)
; CHECK:     call double @__cq_libm_kc(double 3.000000e+00)
; CHECK:     define internal i32 @__cq_q___cq_libm_cbrt_1(i32 %x)
;
; GONE-NOT:  @__cq_libm_exp(
; GONE-NOT:  @__cq_libm_cbrt(
; GONE-NOT:  @__cq_libm_sqrt(
; GONE-NOT:  @__cq_libm_a(
; GONE-NOT:  @__cq_libm_b(
; GONE-NOT:  @__cq_libm_tab
