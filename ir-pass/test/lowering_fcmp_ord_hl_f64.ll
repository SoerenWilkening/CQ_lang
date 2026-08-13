; lowering_fcmp_ord_hl_f64.ll — 8rvn (Phase 7.1 iw81.4 §4.4): `fcmp ord`
; (ordered — neither operand is NaN) is now an in-scope fcmp predicate. A tainted
; data-position `ord` compare with a right-hand f64 literal lowers to
; `cq_template_fcmp_ord_f64_hl(i32, double)`. `ord` is one of the order-test trio
; (`one`/`ord`/`uno`) 8rvn adds; its i1 result is a flag, never a rotation angle.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; CHECK:     call i32 @cqrt_alloc_f64(double 2.000000e+00)
; CHECK:     call i32 @cq_template_fcmp_ord_f64_hl(i32 %{{[a-zA-Z0-9_.]+}}, double 1.000000e+00)
; CHECK:     call i1 @cqrt_measure_i1(i32 %{{[a-zA-Z0-9_.]+}})
;
; CHECK-NOT: = fcmp
; CHECK-NOT: cq_template_icmp

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare double @cq_theta_f64(double, double)
declare i1 @cq_measure_i1(i1)

define i1 @example() {
entry:
  %a = call double @cq_theta_f64(double 2.0, double 5.000000e-01)
  %c = fcmp ord double %a, 1.0
  %m = call i1 @cq_measure_i1(i1 %c)
  ret i1 %m
}
