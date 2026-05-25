; lowering_taint_ui32.ll — Width-parametric taint sources (M14). Pins
; that `@cq_init_ui32` is recognized as a taint source identically to
; `@cq_init_si32`: the init call seeds the work-list, the resulting
; handle is tainted, and the downstream `add i32` is rewritten to a
; Q+Q template call. Same FileCheck shape as `lowering_basic.ll`,
; differing only in the front-end intrinsic suffix.
;
; M14 only widens the SOURCE set in TaintPropagation. The downstream
; lowering (MidHandleRebind / OpcodeLowering / MeasureLowering) still
; uses i32-pinned legacy shims, so this fixture exercises the i32-ABI
; sibling (`ui32`) — same `cqrt_alloc_i32` / `cqrt_measure_i32` /
; `cq_template_add_i32` symbols. Non-i32 suffix coverage lands with
; M15–M17 once the per-width downstream symbols come online.
;
; Spec: phases/phase2/PLAN.md §4.14.

; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -

; CHECK:     call i32 @cqrt_alloc_i32(i32 3)
; CHECK:     call i32 @cqrt_alloc_i32(i32 5)
; CHECK:     call i32 @cq_template_add_i32(
; CHECK:     call i32 @cqrt_measure_i32(

; CHECK-NOT: cq_init_ui32
; CHECK-NOT: cq_measure_ui32
; CHECK-NOT: extractvalue
; CHECK-NOT: insertvalue
; CHECK-NOT: add i32

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

%quint_mid_t = type { i32 }

declare %quint_mid_t @cq_init_ui32(i32)
declare i32          @cq_measure_ui32(%quint_mid_t)

define i32 @example() {
entry:
  %a_struct = call %quint_mid_t @cq_init_ui32(i32 3)
  %a        = extractvalue %quint_mid_t %a_struct, 0

  %b_struct = call %quint_mid_t @cq_init_ui32(i32 5)
  %b        = extractvalue %quint_mid_t %b_struct, 0

  %c        = add i32 %a, %b

  %c_struct = insertvalue %quint_mid_t poison, i32 %c, 0
  %m        = call i32 @cq_measure_ui32(%quint_mid_t %c_struct)

  ret i32 %m
}
