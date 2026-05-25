; lowering_rebind_f64.ll — Width-parametric mid-struct rebind (M15) for
; the f64 ABI. Pins that `qdouble_mid_t` is recognized through
; `WidthDispatch::midStructToSuffix` and that the per-init alloc target
; switches to `cqrt_alloc_f64` (double-valued argument) instead of the
; legacy i32-pinned shim.
;
; Only one frontend suffix maps to the f64 ABI: `f64` (qdouble_mid_t).
; The handle is still i32 across every ABI width per PRD §"Width
; unification"; only the alloc's argument type widens to double. This
; fixture isolates the rebind step: no `fadd`, no measure, so the
; M16/M17 paths (still i32-pinned pre-M17) don't fire.
;
; Spec: phases/phase2/PLAN.md §4.15.

; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -

; CHECK:     call i32 @cqrt_alloc_f64(double 2.718280e+00)

; CHECK-NOT: cq_init_f64
; CHECK-NOT: cqrt_alloc_i32
; CHECK-NOT: extractvalue

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

%qdouble_mid_t = type { double }

declare %qdouble_mid_t @cq_init_f64(double)

define void @example() {
entry:
  %a = call %qdouble_mid_t @cq_init_f64(double 2.718280e+00)
  ret void
}
