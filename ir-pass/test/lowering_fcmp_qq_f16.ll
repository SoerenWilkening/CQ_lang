; lowering_fcmp_qq_f16.ll — Phase 7.1 Increment D × A: a tainted Q+Q
; data-position `fcmp olt` over two f16 thetas lowers to the fp-named bare-QQ
; symbol `cq_template_fcmp_olt_f16(i32, i32)`. Proves (1) the recovered LOGICAL
; width is f16 (from HandleWidth at each `cq_theta_f16` mint — Increment A's
; reader, now extended to the new width), not a laundered i32; (2) the family
; stem is `fcmp` (fp predicate range); (3) compareInScope admits `olt` on the
; QQ path at the new f16 width.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; CHECK:     call i32 @cqrt_alloc_f16(half 0xH4000)
; CHECK:     call i32 @cqrt_alloc_f16(half 0xH4200)
; CHECK:     call i32 @cq_template_fcmp_olt_f16(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call i1 @cqrt_measure_i1(i32 %{{[a-zA-Z0-9_.]+}})
;
; CHECK-NOT: = fcmp olt
; CHECK-NOT: cq_template_icmp
; CHECK-NOT: _f16_hl(
; CHECK-NOT: _f16_lh(

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare half @cq_theta_f16(half, double)
declare i1 @cq_measure_i1(i1)

define i1 @example() {
entry:
  %a = call half @cq_theta_f16(half 0xH4000, double 5.000000e-01)
  %b = call half @cq_theta_f16(half 0xH4200, double 2.500000e-01)
  %c = fcmp olt half %a, %b
  %m = call i1 @cq_measure_i1(i1 %c)
  ret i1 %m
}
