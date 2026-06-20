; lowering_intrinsic_fshl_rotation_i32.ll — Phase 7.1 Increment E: Class-1
; rotate_back bijection. `@llvm.fshl.i32(x, x, 5)` is the ROTATION case
; (arg0==arg1) with a CONSTANT amount; it lowers to the handle+literal additive
; producer `cq_template_fshl_i32_hl(handle, i32 5)`. The Class-1 adjoint is
; rotate-back ((fshl by n)⁻¹ = fshr by n) via the `_inv` twin; whole-DAG reversal
; uses the `_unc` twin. The result is MEASURED so only the forward producer emits.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; CHECK:     call i32 @cqrt_alloc_i32(i32 %u)
; CHECK:     call i32 @cq_template_fshl_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 5)
; CHECK:     call i32 @cqrt_measure_i32(i32 %{{[a-zA-Z0-9_.]+}})
;
; CHECK-NOT: @llvm.fshl

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @llvm.fshl.i32(i32, i32, i32)

define i32 @example(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %r = call i32 @llvm.fshl.i32(i32 %q, i32 %q, i32 5)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
