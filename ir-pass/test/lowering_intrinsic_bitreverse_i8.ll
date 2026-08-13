; lowering_intrinsic_bitreverse_i8.ll — Phase 7.1 Increment E: Class-1 involution
; `bitreverse` at the i8 width (unlike bswap, bitreverse is valid at i8 — it has
; no 16-bit-multiple constraint). `@llvm.bitreverse.i8` lowers to the unary
; additive producer `cq_template_bitreverse_i8(handle)`. Self-inverse involution.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; CHECK:     call i32 @cqrt_alloc_i8(i8 %u)
; CHECK:     call i32 @cq_template_bitreverse_i8(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call i8 @cqrt_measure_i8(i32 %{{[a-zA-Z0-9_.]+}})
;
; CHECK-NOT: @llvm.bitreverse

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i8 @cq_theta_si8(i8, double)
declare i8 @cq_measure_si8(i8)
declare i8 @llvm.bitreverse.i8(i8)

define i8 @example(i8 %u) {
entry:
  %q = call i8 @cq_theta_si8(i8 %u, double 5.000000e-01)
  %r = call i8 @llvm.bitreverse.i8(i8 %q)
  %m = call i8 @cq_measure_si8(i8 %r)
  ret i8 %m
}
