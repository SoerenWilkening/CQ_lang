; lowering_intrinsic_funnel_fshr_general_qq_i32.ll — Phase 7.1 Increment E,
; bd 20xt.1: the fshr (funnel-RIGHT) direction of the general constant-amount
; funnel shift. fshr(a,b,n) = (a<<(W-n))|(b>>n) — the mirror of fshl. With two
; DISTINCT quantum operands and a constant amount it lowers to the ternary qql
; producer `cq_template_fshr_i32_qql(h_a, h_b, i32 7)`; a distinct STEM from fshl
; so its own symbol and `_unc` twin. Both directions are curated in the general
; form. Result MEASURED → forward-only.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; CHECK:     call i32 @cq_template_fshr_i32_qql(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, i32 7)
; CHECK-NOT: @llvm.fshr
; CHECK-NOT: cq_template_fshr_i32_hl

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @llvm.fshr.i32(i32, i32, i32)

define i32 @example(i32 %u, i32 %v) {
entry:
  %a = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %b = call i32 @cq_theta_si32(i32 %v, double 2.500000e-01)
  %r = call i32 @llvm.fshr.i32(i32 %a, i32 %b, i32 7)   ; x != y -> general funnel
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
