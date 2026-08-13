; lowering_add_qc_i64.ll — Per-width Q+C add for the i64 ABI.
; One theta handle + one i64 literal flow through `add i64` and lower
; to `cq_template_add_i64_hl(handle, classical)`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
;
; CHECK:     call i32 @cqrt_alloc_i64(i64 51)
; CHECK:     call i32 @cq_template_add_i64_hl(i32 %{{[a-zA-Z0-9_.]+}}, i64 1000000)
;
; CHECK-NOT: call i32 @cq_template_add_i64(i32 %{{.*}}, i32 %
; CHECK-NOT: cq_theta_sll
; CHECK-NOT: add i64

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i64 @cq_theta_sll(i64, double)

define void @example() {
entry:
  %a = call i64 @cq_theta_sll(i64 51, double 5.000000e-01)
  %c = add i64 %a, 1000000
  ret void
}
