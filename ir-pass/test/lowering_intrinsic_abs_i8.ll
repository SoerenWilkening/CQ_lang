; lowering_intrinsic_abs_i8.ll — Phase 7.1 Increment E: Class-2 unary `abs` with
; the trailing i1 immarg poison flag DROPPED. `@llvm.abs.i8(x, i1 true)` lowers to
; the unary additive producer `cq_template_abs_i8(handle)` — the constant flag is
; not an operand of the lowered op (the lowered op is the TOTAL reversible abs;
; both fwd and `_unc` use the same total f, so the rail zeroes correctly; poison-
; on-INT_MIN is a valid refinement of the source UB). Width i8 from the result.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; CHECK:     call i32 @cqrt_alloc_i8(i8 %u)
; CHECK:     call i32 @cq_template_abs_i8(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call i8 @cqrt_measure_i8(i32 %{{[a-zA-Z0-9_.]+}})
;
; CHECK-NOT: @llvm.abs
; CHECK-NOT: cq_template_abs_i8_inv

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i8 @cq_theta_si8(i8, double)
declare i8 @cq_measure_si8(i8)
declare i8 @llvm.abs.i8(i8, i1)

define i8 @example(i8 %u) {
entry:
  %q = call i8 @cq_theta_si8(i8 %u, double 5.000000e-01)
  %r = call i8 @llvm.abs.i8(i8 %q, i1 true)
  %m = call i8 @cq_measure_si8(i8 %r)
  ret i8 %m
}
