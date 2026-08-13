; measure_only.ll — Theta + measure with no quantum add. The pass lowers
; the source and sink but emits no cq_template_add_i32.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
;
; CHECK:     call i32 @cqrt_alloc_i32(i32 7)
; CHECK:     call i32 @cqrt_measure_i32(
;
; CHECK-NOT: cq_theta_si32
; CHECK-NOT: cq_measure_si32
; CHECK-NOT: cq_template_add_i32

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @measure_only() {
entry:
  %a = call i32 @cq_theta_si32(i32 7, double 5.000000e-01)
  %m = call i32 @cq_measure_si32(i32 %a)
  ret i32 %m
}
