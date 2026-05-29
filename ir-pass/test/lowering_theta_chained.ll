; lowering_theta_chained.ll — Chained theta: the second theta takes the
; first theta's result as its operand. Alloc once, Ry twice on one handle
; (the second theta sees the handle as a tainted operand → no realloc).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; CHECK:        %[[H:.*]] = call i32 @cqrt_alloc_i32(i32 7)
; CHECK:        call void @cqrt_ry_i32(i32 %[[H]], double 1.000000e-01)
; CHECK:        call void @cqrt_ry_i32(i32 %[[H]], double 2.000000e-01)
; CHECK-NOT:    call i32 @cqrt_alloc

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)

define i32 @example() {
entry:
  %a = call i32 @cq_theta_si32(i32 7,  double 1.000000e-01)
  %b = call i32 @cq_theta_si32(i32 %a, double 2.000000e-01)
  ret i32 %b
}
