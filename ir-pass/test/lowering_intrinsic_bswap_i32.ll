; lowering_intrinsic_bswap_i32.ll — Phase 7.1 Increment E: Class-1 bijection
; (involution), unary. A tainted `@llvm.bswap.i32` lowers to the additive
; producer `cq_template_bswap_i32(handle)`; the original llvm intrinsic is gone.
; bswap is a byte-reversal involution (bswap(bswap(x))==x); its `_inv` re-applies
; (Class-1) but the FORWARD (measured) path emits neither `_inv` nor `_unc`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; CHECK:     call i32 @cqrt_alloc_i32(i32 %u)
; CHECK:     call i32 @cq_template_bswap_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call i32 @cqrt_measure_i32(i32 %{{[a-zA-Z0-9_.]+}})
;
; CHECK-NOT: @llvm.bswap
; CHECK-NOT: cq_template_bswap_i32_inv
; CHECK-NOT: cq_template_bswap_i32_unc

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @llvm.bswap.i32(i32)

define i32 @example(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %r = call i32 @llvm.bswap.i32(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
