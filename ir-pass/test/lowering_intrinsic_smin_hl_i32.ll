; lowering_intrinsic_smin_hl_i32.ll — Phase 7.1 Increment E: Class-2 binary, one
; tainted operand + a classical literal (HL). `@llvm.smin.i32(handle, 5)` lowers
; to `cq_template_smin_i32_hl(handle, i32 5)` — the classical operand rides at the
; i32 width. Pins the handle+literal binary shape (mirrors add/mul HL).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
;
; CHECK:     call i32 @cqrt_alloc_i32(i32 %u)
; CHECK:     call i32 @cq_template_smin_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 5)
; CHECK:     call i32 @cqrt_measure_i32(i32 %{{[a-zA-Z0-9_.]+}})
;
; CHECK-NOT: @llvm.smin
; CHECK-NOT: cq_template_smin_i32(i32 %{{.*}}, i32 %

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @llvm.smin.i32(i32, i32)

define i32 @example(i32 %u) {
entry:
  %a = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %r = call i32 @llvm.smin.i32(i32 %a, i32 5)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
