; lowering_add_qq_i32.ll — Per-width Q+Q add for the i32 ABI (M16).
; Two tainted `qint_mid_t` handles flow through `add i32` and lower to
; `cq_template_add_i32(handle, handle)`. The Phase 1 baseline; the
; existing `lowering_basic.ll` covers the full chain through measure,
; while this fixture isolates the per-width add lowering.

; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -

; CHECK:     call i32 @cqrt_alloc_i32(i32 31)
; CHECK:     call i32 @cqrt_alloc_i32(i32 37)
; CHECK:     call i32 @cq_template_add_i32(

; CHECK-NOT: call i32 @cq_template_add_i32_hl(
; CHECK-NOT: cq_init_si32
; CHECK-NOT: add i32

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

%qint_mid_t = type { i32 }

declare %qint_mid_t @cq_init_si32(i32)

define void @example() {
entry:
  %a_struct = call %qint_mid_t @cq_init_si32(i32 31)
  %a        = extractvalue %qint_mid_t %a_struct, 0

  %b_struct = call %qint_mid_t @cq_init_si32(i32 37)
  %b        = extractvalue %qint_mid_t %b_struct, 0

  %c        = add i32 %a, %b
  ret void
}
