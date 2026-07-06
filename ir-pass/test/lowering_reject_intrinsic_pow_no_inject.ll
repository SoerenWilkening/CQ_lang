; lowering_reject_intrinsic_pow_no_inject.ll — DECLINE (p119, Rule 18): `pow` is a
; LIBRARY function. `@llvm.pow.f64` codegens to a libcall (no hardware instruction),
; so — like the transcendentals — its recognizer was removed and a tainted
; un-injected `@llvm.pow.f64(q, 3.0)` rides the loud kMsgUnknownCallee escape
; decline. Note this is the (handle, literal-exponent) shape that used to lower to
; `cq_template_pow_f64_hl`; it must now decline. `pow` is compiled by SOURCE
; INJECTION.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq taint escape: tainted value consumed by an unknown callee
; CHECK-NOT: cq_template_pow

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare double @llvm.pow.f64(double, double)

define double @example(double %u) {
entry:
  %q = call double @cq_theta_f64(double %u, double 5.000000e-01)
  %r = call double @llvm.pow.f64(double %q, double 3.000000e+00)
  %m = call double @cq_measure_f64(double %r)
  ret double %m
}
