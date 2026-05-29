; lowering_measure_f32.ll — Width-parametric measure lowering for the
; f32 ABI: `cq_measure_f32` lowers to `cqrt_measure_f32` (returning
; float). The handle is i32 across every ABI width; only the return type
; varies.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; CHECK:     call i32 @cqrt_alloc_f32(float 1.500000e+00)
; CHECK:     call float @cqrt_measure_f32(i32
;
; CHECK-NOT: cq_theta_f32
; CHECK-NOT: cq_measure_f32
; CHECK-NOT: cqrt_measure_i32

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare float @cq_theta_f32(float, double)
declare float @cq_measure_f32(float)

define float @example() {
entry:
  %a = call float @cq_theta_f32(float 1.500000e+00, double 5.000000e-01)
  %m = call float @cq_measure_f32(float %a)
  ret float %m
}
