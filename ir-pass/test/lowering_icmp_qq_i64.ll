; lowering_icmp_qq_i64.ll — Phase 7.1 Increment A per-width positive. A tainted
; Q+Q data-position `icmp slt` over two i64 thetas lowers to the LOGICAL-width
; bare-QQ symbol `cq_template_icmp_slt_i64(i32, i32)` — NOT a laundered `_i32`
; (after rotation lowering both operands are i32 handles, but the recovered
; `HandleWidth` is i64 from each `cq_theta_sll` mint). This pins that Increment A
; feeds the QQ branch the LOGICAL width, never the i32-laundered SSA type.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; CHECK:     call i32 @cqrt_alloc_i64(i64 51)
; CHECK:     call i32 @cqrt_alloc_i64(i64 53)
; CHECK:     call i32 @cq_template_icmp_slt_i64(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call i1 @cqrt_measure_i1(i32 %{{[a-zA-Z0-9_.]+}})
;
; Logical width is i64, never the laundered i32; and never the HL/LH form.
; CHECK-NOT: = icmp slt
; CHECK-NOT: cq_template_icmp_slt_i32
; CHECK-NOT: _i64_hl(
; CHECK-NOT: _i64_lh(

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i64 @cq_theta_sll(i64, double)
declare i1 @cq_measure_i1(i1)

define i1 @example() {
entry:
  %a = call i64 @cq_theta_sll(i64 51, double 5.000000e-01)
  %b = call i64 @cq_theta_sll(i64 53, double 5.000000e-01)
  %c = icmp slt i64 %a, %b
  %m = call i1 @cq_measure_i1(i1 %c)
  ret i1 %m
}
