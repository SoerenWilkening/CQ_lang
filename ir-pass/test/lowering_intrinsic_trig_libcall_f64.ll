; lowering_intrinsic_trig_libcall_f64.ll — bd 3c6m.71: on a -fmath-errno target
; (Linux's default) clang -O1 emits a libcall `@sin(double)`, not
; `@llvm.sin.f64`. A TAINTED one is rewritten to the intrinsic LangRef defines
; equal to it, so it reaches the same direct route (one `cq_template_sin_f64`):
; errno from a quantum operand has no classical meaning, and the classical
; twin is untouched (it stays `@sin`, system libm). LibmBinding.h.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK:     call i32 @cq_template_sin_f64(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call double @sin(double %c)
; CHECK-NOT: cq taint escape

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare double @sin(double)

define double @example(double %u, double %c) {
  %q = call double @cq_theta_f64(double %u, double 5.000000e-01)
  %s = call double @sin(double %q)
  %m = call double @cq_measure_f64(double %s)
  %k = call double @sin(double %c)
  %z = fadd double %m, %k
  ret double %z
}
