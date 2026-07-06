; lowering_reject_cross_width_lround_no_inject.ll — DECLINE (p119, Rule 18): the
; cross-width ROUND-HALF-AWAY family (`@llvm.lround`/`@llvm.llround`) has no hardware
; fp→int instruction (unlike lrint/llrint, which codegen to cvtsd2si and are KEPT),
; so it lowers to a libcall — a LIBRARY function. Its recognizer was removed from
; `isCrossWidthLibmIntrinsic`, so a tainted un-injected `@llvm.lround.i64.f64(q)`
; rides the loud kMsgUnknownCallee escape decline. This pins the lrint/llrint (keep)
; vs lround/llround (cut) asymmetry — round-to-even is hardware, round-half-away is
; not.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq taint escape: tainted value consumed by an unknown callee
; CHECK-NOT: cq_template_lround

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare double @cq_theta_f64(double, double)
declare i64 @cq_measure_sl(i64)
declare i64 @llvm.lround.i64.f64(double)

define i64 @example(double %u) {
entry:
  %q = call double @cq_theta_f64(double %u, double 5.000000e-01)
  %r = call i64 @llvm.lround.i64.f64(double %q)
  %m = call i64 @cq_measure_sl(i64 %r)
  ret i64 %m
}
