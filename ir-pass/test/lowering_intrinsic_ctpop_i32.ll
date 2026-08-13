; lowering_intrinsic_ctpop_i32.ll — Phase 7.1 Increment E: Class-2 non-injective
; pure-total, unary. A tainted `@llvm.ctpop.i32` (population count) lowers to the
; additive producer `cq_template_ctpop_i32(handle)`. Class-2 has NO `_inv` (ctpop
; is not invertible — many inputs map to the same popcount); it is reversible
; ONLY via the recompute-from-live-source `_unc` twin, exercised in the dead-chain
; fixture lowering_intrinsic_ctpop_sources_live.ll. Here the result is MEASURED,
; so only the forward producer emits.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; CHECK:     call i32 @cqrt_alloc_i32(i32 %u)
; CHECK:     call i32 @cq_template_ctpop_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call i32 @cqrt_measure_i32(i32 %{{[a-zA-Z0-9_.]+}})
;
; CHECK-NOT: @llvm.ctpop
; A non-injective Class-2 op must NEVER mint an `_inv` (it has no inverse).
; CHECK-NOT: cq_template_ctpop_i32_inv

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @llvm.ctpop.i32(i32)

define i32 @example(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %r = call i32 @llvm.ctpop.i32(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
