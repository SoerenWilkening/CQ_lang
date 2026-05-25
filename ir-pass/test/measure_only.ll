; measure_only.ll — Init + measure with no quantum add. The pass should
; still lower the taint source and sink, but emit no cq_template_add_i32.
; Spec: PLAN.md §4.5.

; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -

; CHECK:     call i32 @cqrt_alloc_i32(i32 7)
; CHECK:     call i32 @cqrt_measure_i32(

; CHECK-NOT: cq_init_si32
; CHECK-NOT: cq_measure_si32
; CHECK-NOT: cq_template_add_i32
; CHECK-NOT: extractvalue
; CHECK-NOT: insertvalue

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

%qint_mid_t = type { i32 }

declare %qint_mid_t @cq_init_si32(i32)
declare i32         @cq_measure_si32(%qint_mid_t)

define i32 @measure_only() {
entry:
  %a_struct = call %qint_mid_t @cq_init_si32(i32 7)
  %m        = call i32 @cq_measure_si32(%qint_mid_t %a_struct)
  ret i32 %m
}
