; passthrough_no_quantum.ll — Purely classical add with no cq_* intrinsics.
; The pass must early-out (no cq_init_si32 in the module) and leave the
; classical add i32 untouched. Spec: PLAN.md §4.5.

; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -

; CHECK:     add i32

; CHECK-NOT: cqrt_alloc_i32
; CHECK-NOT: cqrt_measure_i32
; CHECK-NOT: cq_template_add_i32
; CHECK-NOT: cq_init_si32
; CHECK-NOT: cq_measure_si32

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

define i32 @classical_add(i32 %x, i32 %y) {
entry:
  %s = add i32 %x, %y
  ret i32 %s
}
