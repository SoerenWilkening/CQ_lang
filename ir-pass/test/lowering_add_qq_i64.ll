; lowering_add_qq_i64.ll — Per-width Q+Q add for the i64 ABI. Two
; tainted handles from `cq_init_sll` (suffix `sll` maps to ABI width
; `i64`) flow through `add i64` and must lower to
; `cq_template_add_i64(handle, handle)`.

; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -

; CHECK:     call i32 @cqrt_alloc_i64(i64 51)
; CHECK:     call i32 @cqrt_alloc_i64(i64 53)
; CHECK:     call i32 @cq_template_add_i64(

; CHECK-NOT: call i32 @cq_template_add_i64_hl(
; CHECK-NOT: cq_init_sll
; CHECK-NOT: add i64

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

%qlonglong_mid_t = type { i64 }

declare %qlonglong_mid_t @cq_init_sll(i64)

define void @example() {
entry:
  %a_struct = call %qlonglong_mid_t @cq_init_sll(i64 51)
  %a        = extractvalue %qlonglong_mid_t %a_struct, 0

  %b_struct = call %qlonglong_mid_t @cq_init_sll(i64 53)
  %b        = extractvalue %qlonglong_mid_t %b_struct, 0

  %c        = add i64 %a, %b
  ret void
}
