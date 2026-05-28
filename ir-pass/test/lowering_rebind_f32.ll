; lowering_rebind_f32.ll — Width-parametric mid-struct rebind (M15) for
; the f32 ABI. Pins that `qfloat_mid_t` is recognized through
; `WidthDispatch::midStructToSuffix` and that the per-init alloc target
; switches to `cqrt_alloc_f32` (float-valued argument) instead of the
; legacy i32-pinned shim.
;
; Only one frontend suffix maps to the f32 ABI: `f32` (qfloat_mid_t).
; The handle is still i32 across every ABI width per PRD §"Width
; unification"; only the alloc's argument type widens to float. This
; fixture isolates the rebind step: no `fadd`, no measure, so the
; M16/M17 paths (still i32-pinned pre-M17) don't fire.

; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -

; CHECK:     call i32 @cqrt_alloc_f32(float 3.250000e+00)

; CHECK-NOT: cq_init_f32
; CHECK-NOT: cqrt_alloc_i32
; CHECK-NOT: extractvalue

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

%qfloat_mid_t = type { float }

declare %qfloat_mid_t @cq_init_f32(float)

define void @example() {
entry:
  %a = call %qfloat_mid_t @cq_init_f32(float 3.250000e+00)
  ret void
}
