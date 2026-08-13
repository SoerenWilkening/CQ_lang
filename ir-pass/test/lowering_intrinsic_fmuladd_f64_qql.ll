; lowering_intrinsic_fmuladd_f64_qql.ll — Phase 7.1 wd2p: `@llvm.fmuladd.f64` (the
; DEFAULT -O1 contraction of `a*b+c`) maps to the SAME `fma` stem as `@llvm.fma`
; (the trace does not distinguish the may-fuse rounding — a Phase-9 backend
; concern). Here the product is two handles and the addend is a literal 7.0 →
; the QQL shape `cq_template_fma_f64_qql(i32 a, i32 b, double 7.0)`. This is the
; reason wd2p is core, not optional: without it, plain tainted fp expressions
; `a*b+c` silently fail at the validated -O1 floor (kMsgUnknownCallee).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; CHECK:     call i32 @cqrt_alloc_f64(double %u)
; CHECK:     call i32 @cqrt_alloc_f64(double %v)
; CHECK:     call i32 @cq_template_fma_f64_qql(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, double 7.000000e+00)
; CHECK:     call double @cqrt_measure_f64(i32 %{{[a-zA-Z0-9_.]+}})
;
; CHECK-NOT: @llvm.fmuladd
; CHECK-NOT: @llvm.fma
; CHECK-NOT: cqrt_alloc_f64(double 7
; CHECK-NOT: cq_template_fmuladd
; CHECK-NOT: cq_template_fma_f64_qlq
; CHECK-NOT: cq_template_fma_f64_inv

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare double @llvm.fmuladd.f64(double, double, double)

define double @ex(double %u, double %v) {
entry:
  %a = call double @cq_theta_f64(double %u, double 5.000000e-01)
  %b = call double @cq_theta_f64(double %v, double 2.500000e-01)
  %r = call double @llvm.fmuladd.f64(double %a, double %b, double 7.000000e+00)
  %m = call double @cq_measure_f64(double %r)
  ret double %m
}
