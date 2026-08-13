; lowering_add_qq_i32.ll — Per-width Q+Q add for the i32 ABI.
; Two classical thetas allocate two handles that flow through `add i32`
; and lower to `cq_template_add_i32(handle, handle)`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
;
; CHECK:     call i32 @cqrt_alloc_i32(i32 31)
; CHECK:     call void @cqrt_ry_i32(
; CHECK:     call i32 @cqrt_alloc_i32(i32 37)
; CHECK:     call void @cqrt_ry_i32(
; CHECK:     call i32 @cq_template_add_i32(
;
; CHECK-NOT: call i32 @cq_template_add_i32_hl(
; CHECK-NOT: cq_theta_si32
; CHECK-NOT: add i32

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)

define void @example() {
entry:
  %a = call i32 @cq_theta_si32(i32 31, double 5.000000e-01)
  %b = call i32 @cq_theta_si32(i32 37, double 5.000000e-01)
  %c = add i32 %a, %b
  ret void
}
