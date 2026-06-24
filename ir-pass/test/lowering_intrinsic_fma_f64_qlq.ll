; lowering_intrinsic_fma_f64_qlq.ll — Phase 7.1 wd2p: the ternary fma product-pair
; COMMUTATIVE-CANONICALIZATION probe (§7 hazard 4 — operand order). The source
; `@llvm.fma.f64(3.0, q, c)` has the LITERAL factor in product slot 0 and a HANDLE
; in slot 1. fma's product (a*b) is commutative, so the recognizer canonicalizes
; the pair HANDLE-BEFORE-LITERAL: the handle q moves to slot A, the literal 3.0 to
; slot B, the addend c stays positional → the QLQ shape
; `cq_template_fma_f64_qlq(i32 q, double 3.0, i32 c)`. This pins that a literal
; product factor is passed THROUGH as a `double` operand, never promoted to a qubit
; handle (Rule 3 / quantum-classical-handling §5.2), and that the addend is NEVER
; folded into the product (it is positional — the `+ c` term).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; CHECK:     call i32 @cqrt_alloc_f64(double %u)
; CHECK:     call i32 @cqrt_alloc_f64(double %w)
; CHECK:     call i32 @cq_template_fma_f64_qlq(i32 %{{[a-zA-Z0-9_.]+}}, double 3.000000e+00, i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call double @cqrt_measure_f64(i32 %{{[a-zA-Z0-9_.]+}})
;
; CHECK-NOT: @llvm.fma
; CHECK-NOT: cqrt_alloc_f64(double 3
; CHECK-NOT: cq_template_fma_f64_qql
; CHECK-NOT: cq_template_fma_f64_qll
; CHECK-NOT: cq_template_fma_f64_inv

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare double @llvm.fma.f64(double, double, double)

define double @ex(double %u, double %w) {
entry:
  %q = call double @cq_theta_f64(double %u, double 5.000000e-01)
  %c = call double @cq_theta_f64(double %w, double 1.250000e-01)
  %r = call double @llvm.fma.f64(double 3.000000e+00, double %q, double %c)
  %m = call double @cq_measure_f64(double %r)
  ret double %m
}
