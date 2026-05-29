; lowering_add_qc_i8.ll — Per-width Q+C add for the i8 ABI.
; One theta handle + one i8 literal flow through `add i8` and lower
; to `cq_template_add_i8_hl(handle, classical)`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; CHECK:     call i32 @cqrt_alloc_i8(i8 11)
; CHECK:     call i32 @cq_template_add_i8_hl(i32 %{{[a-zA-Z0-9_.]+}}, i8 42)
;
; CHECK-NOT: call i32 @cq_template_add_i8(i32 %{{.*}}, i32 %
; CHECK-NOT: cq_theta_si8
; CHECK-NOT: add i8

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i8 @cq_theta_si8(i8, double)

define void @example() {
entry:
  %a = call i8 @cq_theta_si8(i8 11, double 5.000000e-01)
  %c = add i8 %a, 42
  ret void
}
