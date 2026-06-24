; lowering_fcmp_uge_qq_f16.ll — 8rvn (Phase 7.1 iw81.4 §4.4) × Increment D
; (f16): `fcmp uge` (unordered-or-greater-or-equal) is now in scope. A tainted
; Q+Q data-position `uge` compare over two f16 thetas lowers to the fp-named
; bare-QQ symbol `cq_template_fcmp_uge_f16(i32, i32)`. Proves the new unordered
; twin on the QQ path at the f16 width (logical width recovered from
; `HandleWidth` at each `cq_theta_f16` mint).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; CHECK:     call i32 @cqrt_alloc_f16(half 0xH4000)
; CHECK:     call i32 @cqrt_alloc_f16(half 0xH4200)
; CHECK:     call i32 @cq_template_fcmp_uge_f16(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call i1 @cqrt_measure_i1(i32 %{{[a-zA-Z0-9_.]+}})
;
; CHECK-NOT: = fcmp uge
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
  %c = fcmp uge half %a, %b
  %m = call i1 @cq_measure_i1(i1 %c)
  ret i1 %m
}
