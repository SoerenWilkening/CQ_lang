; lowering_measure_i1.ll — Width-parametric measure lowering for the
; i1 ABI: `cq_measure_i1` lowers to `cqrt_measure_i1` (returning
; i1). The handle is i32 across every ABI width; only the return type
; varies.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
;
; CHECK:     call i32 @cqrt_alloc_i1(i1 true)
; CHECK:     call i1 @cqrt_measure_i1(i32
;
; CHECK-NOT: cq_theta_i1
; CHECK-NOT: cq_measure_i1
; CHECK-NOT: cqrt_measure_i32

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)

define i1 @example() {
entry:
  %a = call i1 @cq_theta_i1(i1 true, double 5.000000e-01)
  %m = call i1 @cq_measure_i1(i1 %a)
  ret i1 %m
}
