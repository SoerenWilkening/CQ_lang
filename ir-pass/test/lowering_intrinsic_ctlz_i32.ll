; lowering_intrinsic_ctlz_i32.ll — Phase 7.1 Increment E: Class-2 unary `ctlz`
; (count-leading-zeros) with the i1 is-zero-undef immarg flag DROPPED. Lowers to
; `cq_template_ctlz_i32(handle)`; the constant flag is not an operand (the lowered
; op is the total function ctlz, with ctlz(0)=W well-defined). No `_inv` (Class-2).
;
; BOTH immarg spellings are asserted (bd ww4c Inc 0). `i1 true` is what
; `__builtin_clz` and LLVM's canonical loop-idiom output emit; `i1 false` is what
; the ww4c recognizer MUST emit, because PoisonFacts.cpp:27-38
; (`curatedIntrinsicCanBePoison`) returns `!Flag || !Flag->isZero()`, so
; PredMuxFlatten (:174-207) accepts a cone containing ctlz/cttz/abs ONLY when the
; immarg is a ConstantInt ZERO. Both lower to the SAME symbol — that is the
; immarg-drop policy of intrinsic_table.yaml:33-38, and this is where it is
; pinned: no e2e golden can witness it, since the immarg never reaches the ABI.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; CHECK-LABEL: @example(
; CHECK:     call i32 @cq_template_ctlz_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call i32 @cqrt_measure_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-LABEL: @example_zero_poison_false(
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

; The `i1 false` form the ww4c recognizer emits — same symbol, same shape.
define i32 @example_zero_poison_false(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 2.500000e-01)
  %r = call i32 @llvm.ctlz.i32(i32 %q, i1 false)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
