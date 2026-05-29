; lowering_add_qc_i1.ll — Per-width Q+C add for the i1 ABI.
; One theta handle + one i1 literal flow through `add i1` and lower
; to `cq_template_add_i1_hl(handle, classical)`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; CHECK:     call i32 @cqrt_alloc_i1(i1 true)
; CHECK:     call i32 @cq_template_add_i1_hl(i32 %{{[a-zA-Z0-9_.]+}}, i1 true)
;
; CHECK-NOT: call i32 @cq_template_add_i1(i32 %{{.*}}, i32 %
; CHECK-NOT: cq_theta_i1
; CHECK-NOT: add i1

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i1 @cq_theta_i1(i1, double)

define void @example() {
entry:
  %a = call i1 @cq_theta_i1(i1 true, double 5.000000e-01)
  %c = add i1 %a, true
  ret void
}
