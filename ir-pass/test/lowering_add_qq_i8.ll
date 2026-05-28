; lowering_add_qq_i8.ll — Per-width Q+Q add for the i8 ABI. Two
; tainted handles from `cq_init_si8` (suffix `si8` maps to ABI width
; `i8`) flow through `add i8` and must lower to
; `cq_template_add_i8(handle, handle)`.
;
; Three frontend suffixes share the i8 ABI (`c`, `si8`, `ui8`); only
; one needs an L3 fixture since signedness is invisible to the IR pass.

; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -

; CHECK:     call i32 @cqrt_alloc_i8(i8 11)
; CHECK:     call i32 @cqrt_alloc_i8(i8 13)
; CHECK:     call i32 @cq_template_add_i8(

; CHECK-NOT: call i32 @cq_template_add_i8_hl(
; CHECK-NOT: cq_init_si8
; CHECK-NOT: add i8

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

%qschar_mid_t = type { i8 }

declare %qschar_mid_t @cq_init_si8(i8)

define void @example() {
entry:
  %a_struct = call %qschar_mid_t @cq_init_si8(i8 11)
  %a        = extractvalue %qschar_mid_t %a_struct, 0

  %b_struct = call %qschar_mid_t @cq_init_si8(i8 13)
  %b        = extractvalue %qschar_mid_t %b_struct, 0

  %c        = add i8 %a, %b
  ret void
}
