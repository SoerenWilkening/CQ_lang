; lowering_theta_alloc_f16.ll — Phase 7.1 Increment D: one classical theta
; for the half-precision f16 ABI. A `cq_theta_f16` (the IEEE `half` source)
; lowers to gate-triggered allocation + Ry (and exercises the §1 cross-type
; RAUW: the `half` theta result is RAUW'd to the i32 alloc handle, guarded by
; the verify RUN line). f16 rides the same width-parametric rotation path as
; f32/f64; abiWidthFromType maps `half` → "f16" (isHalfTy, NOT bfloat).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
;
; CHECK:     call i32 @cqrt_alloc_f16(half 0xH3C00)
; CHECK:     call void @cqrt_ry_f16(i32 %{{[a-zA-Z0-9_.]+}}, double
; CHECK-NOT: cq_theta_f16

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare half @cq_theta_f16(half, double)

define void @example() {
entry:
  %a = call half @cq_theta_f16(half 0xH3C00, double 5.000000e-01)
  ret void
}
