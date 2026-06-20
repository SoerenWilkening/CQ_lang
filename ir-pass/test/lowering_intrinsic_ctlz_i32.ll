; lowering_intrinsic_ctlz_i32.ll — Phase 7.1 Increment E: Class-2 unary `ctlz`
; (count-leading-zeros) with the i1 is-zero-undef immarg flag DROPPED. Lowers to
; `cq_template_ctlz_i32(handle)`; the constant flag is not an operand (the lowered
; op is the total function ctlz, with ctlz(0)=W well-defined). No `_inv` (Class-2).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; CHECK:     call i32 @cq_template_ctlz_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call i32 @cqrt_measure_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: @llvm.ctlz
; CHECK-NOT: cq_template_ctlz_i32_inv

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @llvm.ctlz.i32(i32, i1)

define i32 @example(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %r = call i32 @llvm.ctlz.i32(i32 %q, i1 true)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
