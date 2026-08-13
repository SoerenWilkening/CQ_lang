; lowering_intrinsic_fma_f64_qqq.ll — Phase 7.1 wd2p: the ternary fma family,
; all-handle (QQQ). Three f64 thetas through `@llvm.fma.f64` (the must-fuse
; builtin) lower to the bare-base additive producer `cq_template_fma_f64(i32,
; i32, i32)` — the FIRST 3-operand template. fma is Class-2 (fwd+unc only, no
; inv/controlled); the product pair (a,b) is commutative, the addend c positional,
; and all three operands are quantum handles here so the symbol carries NO shape
; token (exactly like the binary QQ form, so its `_unc` twin attaches to the bare
; base). The `op` stem is `fma` for BOTH llvm.fma and llvm.fmuladd.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; CHECK:     call i32 @cqrt_alloc_f64(double %u)
; CHECK:     call i32 @cqrt_alloc_f64(double %v)
; CHECK:     call i32 @cqrt_alloc_f64(double %w)
; CHECK:     call i32 @cq_template_fma_f64(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call double @cqrt_measure_f64(i32 %{{[a-zA-Z0-9_.]+}})
;
; CHECK-NOT: @llvm.fma
; CHECK-NOT: @llvm.fmuladd
; CHECK-NOT: cq_template_fma_f64_qql
; CHECK-NOT: cq_template_fma_f64_qlq
; CHECK-NOT: cq_template_fma_f64_qll
; CHECK-NOT: cq_template_fma_f64_inv

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare double @llvm.fma.f64(double, double, double)

define double @ex(double %u, double %v, double %w) {
entry:
  %a = call double @cq_theta_f64(double %u, double 5.000000e-01)
  %b = call double @cq_theta_f64(double %v, double 2.500000e-01)
  %c = call double @cq_theta_f64(double %w, double 1.250000e-01)
  %r = call double @llvm.fma.f64(double %a, double %b, double %c)
  %m = call double @cq_measure_f64(double %r)
  ret double %m
}
