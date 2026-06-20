; lowering_measure_f16.ll — Phase 7.1 Increment D: measurement at the f16 ABI.
; A tainted `half` theta handle reaches `cq_measure_f16` and lowers to
; `cqrt_measure_f16(i32 handle)` → half. f16 IS a clean source/sink (unlike
; the deferred i128, whose C ABI shreds to {i64,i64}): the runtime returns
; half (trace-only 0).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; CHECK:     call i32 @cqrt_alloc_f16(half 0xH3C00)
; CHECK:     call half @cqrt_measure_f16(i32 %{{[a-zA-Z0-9_.]+}})
;
; CHECK-NOT: cq_theta_f16
; CHECK-NOT: cq_measure_f16(

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare half @cq_theta_f16(half, double)
declare half @cq_measure_f16(half)

define half @example() {
entry:
  %a = call half @cq_theta_f16(half 0xH3C00, double 5.000000e-01)
  %m = call half @cq_measure_f16(half %a)
  ret half %m
}
