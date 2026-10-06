; libm_bind_accept_alias.ll — bd 3c6m.72, review round 3 finding 2: a program
; that defines `exp` as an external ALIAS of its own function names that function
; under C linkage, so a quantum `llvm.exp.f64` call lifts the aliasee (x+3), not
; the bundle body (x*2). Before the fix `M.getFunction` missed the alias and the
; quantum and classical twins ran different functions.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=GONE < %t.ll
; CHECK:     @exp = alias double (double), ptr @my_exp
; CHECK:     define double @example(double %u0)
; CHECK:     call i32 @__cq_q_my_exp_1(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     define internal i32 @__cq_q_my_exp_1(i32 %x)
; CHECK:     cq_template_fadd_f64_hl(i32 %x, double 3.000000e+00)
; GONE-NOT:  @__cq_libm_exp
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare double @llvm.exp.f64(double)

define double @my_exp(double %x) {
  %y = fadd double %x, 3.000000e+00
  ret double %y
}
@exp = alias double (double), ptr @my_exp
define double @__cq_libm_exp(double %x) {
  %y = fmul double %x, 2.000000e+00
  ret double %y
}

define double @example(double %u0) {
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %s = call double @llvm.exp.f64(double %q)
  %m = call double @cq_measure_f64(double %s)
  ret double %m
}
