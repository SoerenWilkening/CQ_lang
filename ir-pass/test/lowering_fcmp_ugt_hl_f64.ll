; lowering_fcmp_ugt_hl_f64.ll — 8rvn (Phase 7.1 iw81.4 §4.4): `fcmp ugt`
; (unordered-or-greater-than) is now in scope. A tainted data-position `ugt`
; compare with a right-hand f64 literal lowers to
; `cq_template_fcmp_ugt_f64_hl(i32, double)`. `ugt` is one of the unordered
; twins; its NAME overlaps the icmp UNSIGNED predicate, but the `fcmp` family
; stem keeps the symbol distinct (`cq_template_fcmp_ugt_*`, not `_icmp_`).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; CHECK:     call i32 @cqrt_alloc_f64(double 2.000000e+00)
; CHECK:     call i32 @cq_template_fcmp_ugt_f64_hl(i32 %{{[a-zA-Z0-9_.]+}}, double 1.000000e+00)
; CHECK:     call i1 @cqrt_measure_i1(i32 %{{[a-zA-Z0-9_.]+}})
;
; CHECK-NOT: = fcmp
; The fp-family stem must be used — never the integer-named symbol of the same pred.
; CHECK-NOT: cq_template_icmp_ugt

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare double @cq_theta_f64(double, double)
declare i1 @cq_measure_i1(i1)

define i1 @example() {
entry:
  %a = call double @cq_theta_f64(double 2.0, double 5.000000e-01)
  %c = fcmp ugt double %a, 1.0
  %m = call i1 @cq_measure_i1(i1 %c)
  ret i1 %m
}
