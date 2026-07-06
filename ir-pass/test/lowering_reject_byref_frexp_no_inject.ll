; lowering_reject_byref_frexp_no_inject.ll — DECLINE (p119, Rule 18): the by-ref
; math family (`@frexp`/`@modf`/`@remquo`) is a LIBRARY function — the `ByRefMath`
; canonicalization subsystem (epic g387) was DELETED under p119. A tainted
; un-injected `@frexp(q, &e)` is no longer canonicalized to `@cq_byref_*` markers;
; it rides the loud kMsgUnknownCallee escape decline. Coverage of frexp/modf/remquo
; is measured by SOURCE INJECTION (their bodies inline to opcodes). (The unrelated
; g7ip by-ref-out-param INLINER of a VISIBLE user body is kept — see the
; lowering_byref_inline_*.ll fixtures.)
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq taint escape: tainted value consumed by an unknown callee
; CHECK-NOT: cq_byref_
; CHECK-NOT: cq_template_frexp

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare double @frexp(double, i32*)

define double @example(double %u) {
entry:
  %e = alloca i32
  %q = call double @cq_theta_f64(double %u, double 5.000000e-01)
  %r = call double @frexp(double %q, i32* %e)
  %m = call double @cq_measure_f64(double %r)
  ret double %m
}
