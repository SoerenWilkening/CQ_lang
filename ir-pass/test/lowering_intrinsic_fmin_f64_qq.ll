; lowering_intrinsic_fmin_f64_qq.ll — Phase 7.1 iw81.4.b: binary COMMUTATIVE
; fp-math, both operands tainted (QQ). Two f64 thetas through `@llvm.minnum.f64`
; (C99 `fmin`) lower to the bare-QQ additive producer `cq_template_fmin_f64(i32,
; i32)`. fmin is commutative (carries qq+hl, NO lh) and Class-2 (fwd+unc only, no
; inv/controlled). The `op` stem is `fmin`, NOT the llvm name `minnum`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; CHECK:     call i32 @cqrt_alloc_f64(double %u)
; CHECK:     call i32 @cqrt_alloc_f64(double %v)
; CHECK:     call i32 @cq_template_fmin_f64(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call double @cqrt_measure_f64(i32 %{{[a-zA-Z0-9_.]+}})
;
; CHECK-NOT: @llvm.minnum
; CHECK-NOT: @llvm.maxnum
; CHECK-NOT: cq_template_fmin_f64_hl(
; CHECK-NOT: cq_template_fmin_f64_lh
; CHECK-NOT: cq_template_fmin_f64_inv

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare double @llvm.minnum.f64(double, double)

define double @ex(double %u, double %v) {
entry:
  %a = call double @cq_theta_f64(double %u, double 5.000000e-01)
  %b = call double @cq_theta_f64(double %v, double 2.500000e-01)
  %r = call double @llvm.minnum.f64(double %a, double %b)
  %m = call double @cq_measure_f64(double %r)
  ret double %m
}
