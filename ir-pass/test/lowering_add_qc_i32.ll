; lowering_add_qc_i32.ll — Per-width Q+C add for the i32 ABI.
; One theta handle + one i32 literal flow through `add i32` and lower
; to `cq_template_add_i32_hl(handle, classical)`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; CHECK:     call i32 @cqrt_alloc_i32(i32 41)
; CHECK:     call i32 @cq_template_add_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 99)
;
; CHECK-NOT: call i32 @cq_template_add_i32(i32 %{{.*}}, i32 %
; CHECK-NOT: cq_theta_si32
; CHECK-NOT: add i32

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)

define void @example() {
entry:
  %a = call i32 @cq_theta_si32(i32 41, double 5.000000e-01)
  %c = add i32 %a, 99
  ret void
}
