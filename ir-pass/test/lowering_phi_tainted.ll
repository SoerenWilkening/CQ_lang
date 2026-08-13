; lowering_phi_tainted.ll — Phi on a tainted operand lowers to Rz on the
; existing handle (no allocation; phi mints nothing).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
;
; CHECK:     call i32 @cqrt_alloc_i32(i32 4)
; CHECK:     call void @cqrt_ry_i32(
; CHECK:     call void @cqrt_rz_i32(i32 %{{.*}}, double
; CHECK-NOT: cq_phi_si32
; CHECK-NOT: cq_theta_si32

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)

define i32 @example() {
entry:
  %a = call i32 @cq_theta_si32(i32 4, double 5.000000e-01)
  %p = call i32 @cq_phi_si32(i32 %a, double 7.500000e-01)
  ret i32 %p
}
