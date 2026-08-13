; lowering_add_qq_i16.ll — Per-width Q+Q add for the i16 ABI.
; Two classical thetas allocate two handles that flow through `add i16`
; and lower to `cq_template_add_i16(handle, handle)`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; CHECK:     call i32 @cqrt_alloc_i16(i16 21)
; CHECK:     call void @cqrt_ry_i16(
; CHECK:     call i32 @cqrt_alloc_i16(i16 23)
; CHECK:     call void @cqrt_ry_i16(
; CHECK:     call i32 @cq_template_add_i16(
;
; CHECK-NOT: call i32 @cq_template_add_i16_hl(
; CHECK-NOT: cq_theta_si16
; CHECK-NOT: add i16

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i16 @cq_theta_si16(i16, double)

define void @example() {
entry:
  %a = call i16 @cq_theta_si16(i16 21, double 5.000000e-01)
  %b = call i16 @cq_theta_si16(i16 23, double 5.000000e-01)
  %c = add i16 %a, %b
  ret void
}
