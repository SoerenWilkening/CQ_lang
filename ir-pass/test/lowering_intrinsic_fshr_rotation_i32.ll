; lowering_intrinsic_fshr_rotation_i32.ll — Phase 7.1 Increment E: Class-1
; rotate_back, the fshr (rotate-RIGHT) direction. `@llvm.fshr.i32(x, x, 7)` is
; the rotation form (arg0==arg1, constant amount) and lowers to
; `cq_template_fshr_i32_hl(handle, i32 7)`. Distinct adjoint from fshl
; ((fshr by n)⁻¹ = rotate-left by n) — both directions are curated.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
;
; CHECK:     call i32 @cq_template_fshr_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 7)
; CHECK-NOT: @llvm.fshr

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @llvm.fshr.i32(i32, i32, i32)

define i32 @example(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %r = call i32 @llvm.fshr.i32(i32 %q, i32 %q, i32 7)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
