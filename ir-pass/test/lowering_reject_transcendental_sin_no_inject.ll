; lowering_reject_transcendental_sin_no_inject.ll — DECLINE (p119, Rule 18): a
; transcendental is a LIBRARY function. Its `@llvm.sin.f64` intrinsic codegens to a
; libcall (no hardware instruction), so it must be compiled by SOURCE INJECTION
; (its body inlined to opcodes BEFORE this pass). WITHOUT injection, a tainted
; `@llvm.sin.f64(q)` is no longer recognized (the transcendental recognizers were
; removed) and rides the loud kMsgUnknownCallee escape decline. This pins that the
; fp intrinsic admit is the HARDWARE-survivor set ONLY (sqrt/rounding/fabs/copysign/
; fmin/fmax/fma) — a future agent must NOT re-add a per-fn transcendental template.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq taint escape: tainted value consumed by an unknown callee
; CHECK-NOT: cq_template_sin

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare double @llvm.sin.f64(double)

define double @example(double %u) {
entry:
  %q = call double @cq_theta_f64(double %u, double 5.000000e-01)
  %r = call double @llvm.sin.f64(double %q)
  %m = call double @cq_measure_f64(double %r)
  ret double %m
}
