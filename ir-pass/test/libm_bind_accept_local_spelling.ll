; libm_bind_accept_local_spelling.ll — bd 3c6m.72, review round 2 finding F1
; (a verify-clean silent miscompile before the fix): another TU's PRIVATE
; `static double exp(double)` (valid C in a file without math.h) shares the
; spelling of a quantum `llvm.exp.f64` call. Under C linkage it is not the
; math.h function the call names, so the call binds the public bundle body,
; never the helper (x+1 here), and the helper stays untouched. LibmBinding.h:
; only an EXTERNAL program definition wins. (cqc's one-module build lets this
; helper capture the CLASSICAL exp calls of other TUs: bd 3c6m.76, owner ruling
; pending; this module pins the quantum side only.)
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK:     @lib_fp = global ptr @exp
; CHECK:     define internal double @exp(double %x)
; CHECK:     define double @example(double %u0)
; CHECK:     call i32 @__cq_q___cq_libm_exp_1(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     define internal i32 @__cq_q___cq_libm_exp_1(i32 %x)
; CHECK:     cq_template_fmul_f64_hl(i32 %x, double 2.000000e+00)
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare double @llvm.exp.f64(double)

define internal double @exp(double %x) {
  %y = fadd double %x, 1.000000e+00
  ret double %y
}
define double @__cq_libm_exp(double %x) {
  %y = fmul double %x, 2.000000e+00
  ret double %y
}
@lib_fp = global ptr @exp

define double @example(double %u0) {
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %s = call double @llvm.exp.f64(double %q)
  %m = call double @cq_measure_f64(double %s)
  ret double %m
}
