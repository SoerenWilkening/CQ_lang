; lowering_intrinsic_copysign_f64_qq.ll — Phase 7.1 iw81.4.b: binary
; NON-commutative fp-math, both operands tainted (QQ). `@llvm.copysign.f64(a, b)`
; (magnitude of a, sign of b) lowers to the bare-name QQ producer
; `cq_template_copysign_f64(i32, i32)` — the QQ form carries NO `_qq` suffix (it
; attaches `_unc` to the bare base, matching TemplateName shapeSuffix(QQ)="").
;
; THE SILENT-MISCOMPILE GUARD this pins: copysign is order-sensitive
; (copysign(a,b) != copysign(b,a)), so the QQ operands MUST be emitted in SOURCE
; order — NEVER BirthOrder-canonicalized (that sort is for COMMUTATIVE ops only).
; The CHECK captures the two alloc'd handles and asserts the `%u`-derived handle
; (a, the magnitude source) is operand 0 and the `%v`-derived handle (b, the sign
; source) is operand 1 — a flipped order would compute the wrong copysign.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; CHECK:     %[[A:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double %u)
; CHECK:     %[[B:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double %v)
; CHECK:     call i32 @cq_template_copysign_f64(i32 %[[A]], i32 %[[B]])
; CHECK:     call double @cqrt_measure_f64(i32 %{{[a-zA-Z0-9_.]+}})
;
; CHECK-NOT: @llvm.copysign
; CHECK-NOT: cq_template_copysign_f64_qq
; CHECK-NOT: cq_template_copysign_f64_lh
; CHECK-NOT: cq_template_copysign_f64_inv

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare double @llvm.copysign.f64(double, double)

define double @ex(double %u, double %v) {
entry:
  %a = call double @cq_theta_f64(double %u, double 5.000000e-01)
  %b = call double @cq_theta_f64(double %v, double 2.500000e-01)
  %r = call double @llvm.copysign.f64(double %a, double %b)
  %m = call double @cq_measure_f64(double %r)
  ret double %m
}
