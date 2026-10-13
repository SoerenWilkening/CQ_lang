; spec_accept_callconv_fastcc_retarget.ll — ACCEPT (bd r2j3.25).
;
; A `static` callee is `internal fastcc` after clang -O1 (GlobalOpt), and
; `CloneFunction` / `retypeCloneSignature` give its clone the same calling
; convention. When the clone's return type differs from the call's (here a tainted
; double return retyped to the i32 handle), `retargetSite` REBUILDS the call, and
; the rebuilt call used to be a default `ccc` call of the `fastcc` clone: a
; calling-convention mismatch is undefined behaviour that `opt -verify` does not
; report (found on slice_libm_real_coshl, `@__cq_q_olm_expl_1`, bd p3kd.13 review).
; The call now takes the CLONE's convention, as `EmitInverse` already makes a twin
; call take the twin's.
;
; C source (clang -O1, then the IR below trimmed of attributes and metadata):
;   static __attribute__((noinline)) double sh(double x) { return x * 2.0 + 1.0; }
;   double ex_fastcc(double u0) {
;     double q = u0;
;     cq_theta(&q, 0.5);
;     return cq_measure(sh(q));
;   }
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare double @llvm.fmuladd.f64(double, double, double)

define internal fastcc noundef double @sh(double noundef %0) unnamed_addr {
  %2 = tail call double @llvm.fmuladd.f64(double %0, double 2.000000e+00, double 1.000000e+00)
  ret double %2
}

define double @ex_fastcc(double noundef %0) {
  %2 = tail call double @cq_theta_f64(double noundef %0, double noundef 5.000000e-01)
  %3 = tail call fastcc double @sh(double noundef %2)
  %4 = tail call double @cq_measure_f64(double noundef %3)
  ret double %4
}

; CHECK-LABEL: define double @ex_fastcc(
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double %0)
; CHECK:     %[[R:[a-zA-Z0-9_.]+]] = call fastcc i32 @__cq_q_sh_1(i32 %[[H]])
; CHECK:     call double @cqrt_measure_f64(i32 %[[R]])
; CHECK:     define internal fastcc i32 @__cq_q_sh_1(i32
