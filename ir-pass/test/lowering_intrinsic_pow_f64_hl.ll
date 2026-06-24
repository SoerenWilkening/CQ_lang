; lowering_intrinsic_pow_f64_hl.ll — Phase 7.1 iw81.4.b: binary NON-commutative
; fp-math. A tainted `@llvm.pow.f64(q, 3.0)` (handle, fp literal) lowers to the
; handle-on-left producer `cq_template_pow_f64_hl(i32 handle, double 3.0)`. pow is
; order-sensitive (pow(x,y) != pow(y,x)), so it carries the qq+hl+lh grid — the
; HL form pins that the fp literal is passed THROUGH as a `double` operand, never
; promoted to a qubit handle (Rule 3 / quantum-classical-handling §5.2).
;
; NOTE: pow(q, 2.0)/pow(q,0.5) fold at -O1 to fmul/@llvm.sqrt; a non-folding
; literal (3.0) is used so the `@llvm.pow` HL form is exercised directly.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; CHECK:     call i32 @cqrt_alloc_f64(double %u)
; CHECK:     call i32 @cq_template_pow_f64_hl(i32 %{{[a-zA-Z0-9_.]+}}, double 3.000000e+00)
; CHECK:     call double @cqrt_measure_f64(i32 %{{[a-zA-Z0-9_.]+}})
;
; CHECK-NOT: @llvm.pow
; CHECK-NOT: cqrt_alloc_f64(double 3
; CHECK-NOT: cq_template_pow_f64_lh
; CHECK-NOT: cq_template_pow_f64_inv

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare double @llvm.pow.f64(double, double)

define double @ex(double %u) {
entry:
  %q = call double @cq_theta_f64(double %u, double 5.000000e-01)
  %r = call double @llvm.pow.f64(double %q, double 3.000000e+00)
  %m = call double @cq_measure_f64(double %r)
  ret double %m
}
