; lowering_reject_libm_direct_cbrt_no_inject.ll — DECLINE (p119, Rule 18): a DIRECT
; libm call (`@cbrt`, and the whole erf/tgamma/atan2/hypot/ilogb/ldexp/scalbn/…
; family) is a LIBRARY function — it must be compiled by SOURCE INJECTION, not by
; name-recognition. The `LibmLowering` direct-`@name` matcher was DELETED, so a
; tainted un-injected `@cbrt(q)` rides the loud kMsgUnknownCallee escape decline
; (its body inlines to opcodes+branches once injected — that is where coverage is
; measured). Pins that no direct-libm name is silently recognized.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq taint escape: tainted value consumed by an unknown callee
; CHECK-NOT: cq_template_cbrt

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare double @cbrt(double)

define double @example(double %u) {
entry:
  %q = call double @cq_theta_f64(double %u, double 5.000000e-01)
  %r = call double @cbrt(double %q)
  %m = call double @cq_measure_f64(double %r)
  ret double %m
}
