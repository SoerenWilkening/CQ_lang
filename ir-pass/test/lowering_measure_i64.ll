; lowering_measure_i64.ll — Width-parametric measure lowering for the
; i64 ABI: `cq_measure_sll` lowers to `cqrt_measure_i64` (returning
; i64). The handle is i32 across every ABI width; only the return type
; varies.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
;
; CHECK:     call i32 @cqrt_alloc_i64(i64 99)
; CHECK:     call i64 @cqrt_measure_i64(i32
;
; CHECK-NOT: cq_theta_sll
; CHECK-NOT: cq_measure_sll
; CHECK-NOT: cqrt_measure_i32

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i64 @cq_theta_sll(i64, double)
declare i64 @cq_measure_sll(i64)

define i64 @example() {
entry:
  %a = call i64 @cq_theta_sll(i64 99, double 5.000000e-01)
  %m = call i64 @cq_measure_sll(i64 %a)
  ret i64 %m
}
