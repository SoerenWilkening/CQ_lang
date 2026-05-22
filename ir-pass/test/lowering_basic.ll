; lowering_basic.ll — Standard lowering: two taint sources, one tainted add,
; one measurement. Port of prototype/test/input.ll updated to Phase 1's
; measure signature (cq_measure_i32 returns i32, not i64). Spec: PLAN.md §4.5.

; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -

; CHECK:     call i32 @cqrt_alloc_classical_i32(i32 3)
; CHECK:     call i32 @cqrt_alloc_classical_i32(i32 5)
; CHECK:     call i32 @cq_template_add_i32(
; CHECK:     call i32 @cqrt_measure_i32(

; CHECK-NOT: cq_init_i32
; CHECK-NOT: cq_measure_i32{{[^_]}}
; CHECK-NOT: extractvalue
; CHECK-NOT: insertvalue
; CHECK-NOT: add i32

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

%qint_mid_t = type { i32 }

declare %qint_mid_t @cq_init_i32(i32)
declare i32         @cq_measure_i32(%qint_mid_t)

define i32 @example() {
entry:
  %a_struct = call %qint_mid_t @cq_init_i32(i32 3)
  %a        = extractvalue %qint_mid_t %a_struct, 0

  %b_struct = call %qint_mid_t @cq_init_i32(i32 5)
  %b        = extractvalue %qint_mid_t %b_struct, 0

  %c        = add i32 %a, %b

  %c_struct = insertvalue %qint_mid_t poison, i32 %c, 0
  %m        = call i32 @cq_measure_i32(%qint_mid_t %c_struct)

  ret i32 %m
}
