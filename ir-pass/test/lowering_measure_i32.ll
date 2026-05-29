; lowering_measure_i32.ll — Width-parametric measure lowering for the
; i32 ABI: `cq_measure_si32` lowers to `cqrt_measure_i32` (returning
; i32). The handle is i32 across every ABI width; only the return type
; varies.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; CHECK:     call i32 @cqrt_alloc_i32(i32 99)
; CHECK:     call i32 @cqrt_measure_i32(i32
;
; CHECK-NOT: cq_theta_si32
; CHECK-NOT: cq_measure_si32

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example() {
entry:
  %a = call i32 @cq_theta_si32(i32 99, double 5.000000e-01)
  %m = call i32 @cq_measure_si32(i32 %a)
  ret i32 %m
}
