; lowering_intrinsic_sin_f64.ll — Phase 7.1 iw81.4.b: the unary fp-math family.
; A tainted `@llvm.sin.f64` (the headline transcendental) lowers to the Class-2
; additive producer `cq_template_sin_f64(handle)`. sin is non-injective pure
; total (fwd+unc only, no inv/controlled); the fp data handle is i32 (signedness
; / fp-ness stripped — the width only selects the symbol). A purely MEASURED sin
; is a live terminal, so no `_unc` here (the dead-lineage `_unc` twin is proven by
; the e2e golden / the f16/ctpop slices).
;
; SAFETY: this is a fp-DATA use of `q` (arg-0 of sin). The angle fence — a tainted
; sin result reaching a rotation arg-1 — is positional and declines elsewhere
; (lowering_reject_math_result_as_angle_sin.ll), never here.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; CHECK:     call i32 @cqrt_alloc_f64(double %u)
; CHECK:     call void @cqrt_ry_f64(i32 %{{[a-zA-Z0-9_.]+}}, double 5.000000e-01)
; CHECK:     call i32 @cq_template_sin_f64(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call double @cqrt_measure_f64(i32 %{{[a-zA-Z0-9_.]+}})
;
; CHECK-NOT: @llvm.sin
; CHECK-NOT: cq_template_sin_f64_hl(
; CHECK-NOT: cq_template_sin_f64_inv
; CHECK-NOT: cq_template_sin_f64_unc

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare double @llvm.sin.f64(double)

define double @ex(double %u) {
entry:
  %q = call double @cq_theta_f64(double %u, double 5.000000e-01)
  %r = call double @llvm.sin.f64(double %q)
  %m = call double @cq_measure_f64(double %r)
  ret double %m
}
