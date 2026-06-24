; lowering_reject_fma_literal_product.ll — DECLINE: a ternary fma whose PRODUCT
; PAIR is all-classical (`@llvm.fma.f64(2.0, 3.0, q)` — literal*literal + handle).
; Every curated fma shape (qqq/qql/qlq/qll) begins with a HANDLE in product slot A
; (the recognizer canonicalizes the commutative pair handle-before-literal); there
; is NO `llq` shape, so the recognizer DECLINES loudly rather than mint a phantom
; symbol or mis-route the literal product as a handle. This is a defensive probe:
; clang const-folds a literal*literal product, so a real fma never lands here — but
; the explicit `!P0T && !P1T` guard is the load-bearing safety net (Prime Directive:
; when the shape is unproven, decline; over-declining is safe, over-accepting is a
; silent miscompile). The tainted addend keeps the fma in the taint set (so it is
; enqueued, not escape-declined) — it is the recognizer's own ternary arm that
; declines.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare double @llvm.fma.f64(double, double, double)

define double @example(double %u) {
entry:
  %a = call double @cq_theta_f64(double %u, double 5.000000e-01)
  %r = call double @llvm.fma.f64(double 2.000000e+00, double 3.000000e+00, double %a)
  %m = call double @cq_measure_f64(double %r)
  ret double %m
}

; CHECK: error{{.*}}no template for opcode 'call double' in tainted context
; CHECK-NOT: cq_template_fma
