; lowering_add_qq_i8.ll — Per-width Q+Q add for the i8 ABI.
; Two classical thetas allocate two handles that flow through `add i8`
; and lower to `cq_template_add_i8(handle, handle)`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
;
; CHECK:     call i32 @cqrt_alloc_i8(i8 11)
; CHECK:     call void @cqrt_ry_i8(
; CHECK:     call i32 @cqrt_alloc_i8(i8 13)
; CHECK:     call void @cqrt_ry_i8(
; CHECK:     call i32 @cq_template_add_i8(
;
; CHECK-NOT: call i32 @cq_template_add_i8_hl(
; CHECK-NOT: cq_theta_si8
; CHECK-NOT: add i8

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i8 @cq_theta_si8(i8, double)

define void @example() {
entry:
  %a = call i8 @cq_theta_si8(i8 11, double 5.000000e-01)
  %b = call i8 @cq_theta_si8(i8 13, double 5.000000e-01)
  %c = add i8 %a, %b
  ret void
}
