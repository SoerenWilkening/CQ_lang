; lowering_add_qq_i16.ll — Per-width Q+Q add for the i16 ABI (M16). Two
; tainted handles from `cq_init_si16` (suffix `si16` maps to ABI width
; `i16`) flow through `add i16` and must lower to
; `cq_template_add_i16(handle, handle)`.
;
; Spec: phases/phase2/PLAN.md §4.16.

; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -

; CHECK:     call i32 @cqrt_alloc_i16(i16 21)
; CHECK:     call i32 @cqrt_alloc_i16(i16 23)
; CHECK:     call i32 @cq_template_add_i16(

; CHECK-NOT: call i32 @cq_template_add_i16_hl(
; CHECK-NOT: cq_init_si16
; CHECK-NOT: add i16

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

%qshort_mid_t = type { i16 }

declare %qshort_mid_t @cq_init_si16(i16)

define void @example() {
entry:
  %a_struct = call %qshort_mid_t @cq_init_si16(i16 21)
  %a        = extractvalue %qshort_mid_t %a_struct, 0

  %b_struct = call %qshort_mid_t @cq_init_si16(i16 23)
  %b        = extractvalue %qshort_mid_t %b_struct, 0

  %c        = add i16 %a, %b
  ret void
}
