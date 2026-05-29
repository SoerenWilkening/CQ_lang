; lowering_add_qc_i16.ll — Per-width Q+C add for the i16 ABI.
; One theta handle + one i16 literal flow through `add i16` and lower
; to `cq_template_add_i16_hl(handle, classical)`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; CHECK:     call i32 @cqrt_alloc_i16(i16 21)
; CHECK:     call i32 @cq_template_add_i16_hl(i32 %{{[a-zA-Z0-9_.]+}}, i16 100)
;
; CHECK-NOT: call i32 @cq_template_add_i16(i32 %{{.*}}, i32 %
; CHECK-NOT: cq_theta_si16
; CHECK-NOT: add i16

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i16 @cq_theta_si16(i16, double)

define void @example() {
entry:
  %a = call i16 @cq_theta_si16(i16 21, double 5.000000e-01)
  %c = add i16 %a, 100
  ret void
}
