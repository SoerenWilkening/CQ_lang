; lowering_theta_alloc_i16.ll — One classical theta for the i16 ABI:
; gate-triggered allocation + Ry.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
;
; CHECK:     call i32 @cqrt_alloc_i16(i16 99)
; CHECK:     call void @cqrt_ry_i16(i32 %{{[a-zA-Z0-9_.]+}}, double
; CHECK-NOT: cq_theta_si16

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i16 @cq_theta_si16(i16, double)

define void @example() {
entry:
  %a = call i16 @cq_theta_si16(i16 99, double 5.000000e-01)
  ret void
}
