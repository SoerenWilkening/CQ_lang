; lowering_measure_f64.ll — Width-parametric measure lowering for the
; f64 ABI: `cq_measure_f64` lowers to `cqrt_measure_f64` (returning
; double). The handle is i32 across every ABI width; only the return type
; varies.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
;
; CHECK:     call i32 @cqrt_alloc_f64(double 2.718280e+00)
; CHECK:     call double @cqrt_measure_f64(i32
;
; CHECK-NOT: cq_theta_f64
; CHECK-NOT: cq_measure_f64
; CHECK-NOT: cqrt_measure_i32

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @example() {
entry:
  %a = call double @cq_theta_f64(double 2.718280e+00, double 5.000000e-01)
  %m = call double @cq_measure_f64(double %a)
  ret double %m
}
