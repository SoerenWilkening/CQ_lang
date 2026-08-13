; lowering_theta_alloc_f64.ll — One classical theta for the f64 ABI:
; gate-triggered allocation + Ry (and the §1 cross-type-RAUW invariant via the verify RUN
; line — the double theta result is RAUW'd to the i32 alloc handle).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
;
; CHECK:     call i32 @cqrt_alloc_f64(double 9.900000e+01)
; CHECK:     call void @cqrt_ry_f64(i32 %{{[a-zA-Z0-9_.]+}}, double
; CHECK-NOT: cq_theta_f64

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare double @cq_theta_f64(double, double)

define void @example() {
entry:
  %a = call double @cq_theta_f64(double 9.900000e+01, double 5.000000e-01)
  ret void
}
