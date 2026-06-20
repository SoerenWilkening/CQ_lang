; lowering_fcmp_qq_f64.ll — Phase 7.1 Increment A per-width FP positive. A
; tainted Q+Q data-position `fcmp olt` over two f64 thetas lowers to the
; fp-named bare-QQ symbol `cq_template_fcmp_olt_f64(i32, i32)`. This proves
; three things at once on the QQ path: (1) the recovered LOGICAL width is f64
; (from each `cq_theta_f64` mint), not the laundered i32; (2) the family stem is
; `fcmp` (the fp predicate range), not `icmp`; (3) `compareInScope` admits the
; in-scope `olt` predicate on the QQ path exactly as it does on HL.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; CHECK:     call i32 @cqrt_alloc_f64(double 2.000000e+00)
; CHECK:     call i32 @cqrt_alloc_f64(double 3.000000e+00)
; CHECK:     call i32 @cq_template_fcmp_olt_f64(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call i1 @cqrt_measure_i1(i32 %{{[a-zA-Z0-9_.]+}})
;
; The bare `fcmp` must be gone; no integer-named symbol; not the HL form.
; CHECK-NOT: = fcmp olt
; CHECK-NOT: cq_template_icmp
; CHECK-NOT: _f64_hl(
; CHECK-NOT: _f64_lh(

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare double @cq_theta_f64(double, double)
declare i1 @cq_measure_i1(i1)

define i1 @example() {
entry:
  %a = call double @cq_theta_f64(double 2.0, double 5.000000e-01)
  %b = call double @cq_theta_f64(double 3.0, double 2.500000e-01)
  %c = fcmp olt double %a, %b
  %m = call i1 @cq_measure_i1(i1 %c)
  ret i1 %m
}
