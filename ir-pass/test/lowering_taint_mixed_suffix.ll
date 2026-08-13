; lowering_taint_mixed_suffix.ll — Two distinct front-end suffixes (si32 and
; ui32) coexist; each theta is a separate taint source and both handles flow
; through a single tainted `add i32` that lowers to Q+Q. Confirms the
; enumeration walks the full suffix list, not a single fixed name.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
;
; CHECK:     call i32 @cqrt_alloc_i32(i32 11)
; CHECK:     call i32 @cqrt_alloc_i32(i32 13)
; CHECK:     call i32 @cq_template_add_i32(
; CHECK:     call i32 @cqrt_measure_i32(
;
; CHECK-NOT: cq_theta_si32
; CHECK-NOT: cq_theta_ui32
; CHECK-NOT: cq_measure_si32
; CHECK-NOT: add i32

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_theta_ui32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @mixed() {
entry:
  %a = call i32 @cq_theta_si32(i32 11, double 5.000000e-01)
  %b = call i32 @cq_theta_ui32(i32 13, double 5.000000e-01)
  %c = add i32 %a, %b
  %m = call i32 @cq_measure_si32(i32 %c)
  ret i32 %m
}
