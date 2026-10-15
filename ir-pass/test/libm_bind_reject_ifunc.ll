; libm_bind_reject_ifunc.ll — bd 3c6m.72, review round 3 finding 2: a program
; `log` defined as an ifunc is resolved at load time and has no body to lift,
; so a quantum `llvm.log.f64` call binds nothing (neither the resolver's pick nor
; the bundle) and fails loudly as an unknown callee (LibmBinding.h).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq taint escape: tainted value consumed by an unknown callee
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare double @llvm.log.f64(double)

define double @my_log(double %x) {
  %y = fadd double %x, 5.000000e+00
  ret double %y
}
define ptr @resolve_log() {
  ret ptr @my_log
}
@log = ifunc double (double), ptr @resolve_log
define double @__cq_libm_log(double %x) {
  %y = fmul double %x, 7.000000e+00
  ret double %y
}

define double @example(double %u0) {
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %s = call double @llvm.log.f64(double %q)
  %m = call double @cq_measure_f64(double %s)
  ret double %m
}
