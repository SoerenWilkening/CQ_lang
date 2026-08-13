; lowering_intrinsic_funnel_fshl_general_qq_i32.ll — Phase 7.1 Increment E,
; bd 20xt.1: the GENERAL constant-amount funnel shift (arg0 != arg1). This is
; NOT the rotation form — it concatenates two DISTINCT quantum operands (%a high,
; %b low) and extracts a shifted window: fshl(a,b,16) = (a<<16)|(b>>16), the
; `(ix<<16)|(i0>>16)` ld80 word-extract idiom (s_erfl.c:264/343, erfl/erfcl).
; It is a Class-2 NON-injective additive producer (lossy jointly over (a,b)), so
; it lowers to the ternary qql shape `cq_template_fshl_i32_qql(h_a, h_b, i32 16)`
; (Rule 14 — the amount 16 rides the qql literal slot; a distinct STEM gives a
; distinct symbol from the fma qql). BOTH data operands must be quantum handles;
; the amount is a compile-time constant. The result is MEASURED so only the
; forward producer emits (no `_unc`). No `_inv` twin exists (Class-2).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
;
; CHECK:     call i32 @cqrt_alloc_i32(i32 %u)
; CHECK:     call i32 @cqrt_alloc_i32(i32 %v)
; CHECK:     call i32 @cq_template_fshl_i32_qql(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, i32 16)
; CHECK:     call i32 @cqrt_measure_i32(i32 %{{[a-zA-Z0-9_.]+}})
;
; CHECK-NOT: @llvm.fshl
; CHECK-NOT: cq_template_fshl_i32_hl
; CHECK-NOT: cq_template_fshl_i32_qql_inv

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @llvm.fshl.i32(i32, i32, i32)

define i32 @example(i32 %u, i32 %v) {
entry:
  %a = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %b = call i32 @cq_theta_si32(i32 %v, double 2.500000e-01)
  %r = call i32 @llvm.fshl.i32(i32 %a, i32 %b, i32 16)   ; x != y -> general funnel, both tainted
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
