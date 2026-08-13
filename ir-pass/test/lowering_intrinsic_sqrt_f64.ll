; lowering_intrinsic_sqrt_f64.ll — Phase 7.1 iw81.4.b: the RED->GREEN FLIP of the
; former over-accept fence lowering_reject_intrinsic_transcendental_sqrt.ll.
;
; Until iw81.4.b, an fp transcendental (`@llvm.sqrt`/`sin`/…) was deliberately NOT
; curated — `isCuratedReversibleIntrinsic` returned false (every fp width was out
; of widthInTableSet), so a tainted sqrt rode the loud kMsgUnknownCallee escape
; decline. iw81.4.b curates the fp-math family as Class-2 recompute-from-live-
; source producers, so `@llvm.sqrt.f64(q)` now lowers to `cq_template_sqrt_f64`.
; sqrt is injective on its domain but is uniformly Class-2 (its `_unc` recomputes
; sqrt(live source) and XORs the out rail to |0⟩ — never recovering the input);
; the negative-operand domain (NaN) is a deferred Phase-9 backend |0⟩-rail proof,
; mirroring the shipped abs-on-INT_MIN precedent.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
;
; CHECK:     call i32 @cqrt_alloc_f64(double %u)
; CHECK:     call i32 @cq_template_sqrt_f64(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call double @cqrt_measure_f64(i32 %{{[a-zA-Z0-9_.]+}})
;
; CHECK-NOT: @llvm.sqrt
; CHECK-NOT: cq taint escape
; CHECK-NOT: cq_template_sqrt_f64_inv

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare double @llvm.sqrt.f64(double)

define double @ex(double %u) {
entry:
  %q = call double @cq_theta_f64(double %u, double 5.000000e-01)
  %r = call double @llvm.sqrt.f64(double %q)
  %m = call double @cq_measure_f64(double %r)
  ret double %m
}
