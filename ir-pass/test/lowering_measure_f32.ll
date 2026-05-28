; lowering_measure_f32.ll — Width-parametric measure lowering for
; the f32 ABI. Pins that `cq_measure_f32` lowers to `cqrt_measure_f32`
; (returning float) instead of the legacy i32-pinned shim.
;
; Only one frontend suffix maps to the f32 ABI: `f32` (qfloat_mid_t).
; The handle is still i32 across every ABI width per PRD §"Width
; unification"; only the measure's return type widens to float. Init
; flows directly into measure (operand pattern (a) — struct→handle via
; rebind).

; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -

; CHECK:     call i32 @cqrt_alloc_f32(float 3.250000e+00)
; CHECK:     call float @cqrt_measure_f32(i32

; CHECK-NOT: cq_init_f32
; CHECK-NOT: cq_measure_f32
; CHECK-NOT: cqrt_measure_i32

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

%qfloat_mid_t = type { float }

declare %qfloat_mid_t @cq_init_f32(float)
declare float         @cq_measure_f32(%qfloat_mid_t)

define float @example() {
entry:
  %a_struct = call %qfloat_mid_t @cq_init_f32(float 3.250000e+00)
  %m        = call float @cq_measure_f32(%qfloat_mid_t %a_struct)
  ret float %m
}
