; lowering_fadd_qq_f16.ll — Phase 7.1 Increment D: per-width Q+Q fadd for the
; half-precision f16 ABI. Two classical thetas allocate two `half` handles that
; flow through `fadd half` and lower to `cq_template_fadd_f16(handle, handle)`.
; Proves the f16 binary surface (fadd_f16 Q+Q), regenerated from the YAML.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; CHECK:     call i32 @cqrt_alloc_f16(half 0xH4000)
; CHECK:     call void @cqrt_ry_f16(
; CHECK:     call i32 @cqrt_alloc_f16(half 0xH4200)
; CHECK:     call void @cqrt_ry_f16(
; CHECK:     call i32 @cq_template_fadd_f16(
;
; CHECK-NOT: call i32 @cq_template_fadd_f16_hl(
; CHECK-NOT: cq_theta_f16
; CHECK-NOT: fadd half

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare half @cq_theta_f16(half, double)

define void @example() {
entry:
  %a = call half @cq_theta_f16(half 0xH4000, double 5.000000e-01)
  %b = call half @cq_theta_f16(half 0xH4200, double 5.000000e-01)
  %c = fadd half %a, %b
  ret void
}
