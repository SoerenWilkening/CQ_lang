; lowering_rebind_i16.ll — Width-parametric mid-struct rebind (M15) for
; the i16 ABI. Pins that `qshort_mid_t` is recognized through
; `WidthDispatch::midStructToSuffix` and that the per-init alloc target
; switches to `cqrt_alloc_i16` instead of the legacy i32-pinned shim.
;
; Two frontend suffixes share the i16 ABI (`si16`, `ui16`); only one
; needs an L3 fixture. We pick `si16` (qshort_mid_t).
;
; The handle is still i32 across every ABI width per PRD §"Width
; unification"; only the alloc's argument type widens. This fixture
; isolates the rebind step: no `add`, no measure, so the M16/M17 paths
; (still i32-pinned pre-M17) don't fire.
;
; Spec: phases/phase2/PLAN.md §4.15.

; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -

; CHECK:     call i32 @cqrt_alloc_i16(i16 42)

; CHECK-NOT: cq_init_si16
; CHECK-NOT: cqrt_alloc_i32
; CHECK-NOT: extractvalue

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

%qshort_mid_t = type { i16 }

declare %qshort_mid_t @cq_init_si16(i16)

define void @example() {
entry:
  %a = call %qshort_mid_t @cq_init_si16(i16 42)
  ret void
}
