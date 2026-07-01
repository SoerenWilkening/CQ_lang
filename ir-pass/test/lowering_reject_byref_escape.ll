; lowering_reject_byref_escape.ll — bd g387 decline (Prime Directive, miss-safety).
; The out-param cell's address escapes to a SECOND call (`@sink`), so the pass
; cannot prove it accounts for every read of the cell (a later read through the
; escaped pointer would stay classical while it is a function of the quantum
; input — a silent miscompile). Decline LOUDLY; lower nothing.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
;
; CHECK: cq by-ref math out-param under quantum lift (out-param cell escapes to an unsupported use)

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare double @cq_theta_f64(double, double)
declare i32 @cq_measure_si32(i32)
declare double @frexp(double, ptr)
declare void @sink(ptr)

define i32 @ex() {
entry:
  %e = alloca i32, align 4
  %q = call double @cq_theta_f64(double 0.000000e+00, double 5.000000e-01)
  %m = call double @frexp(double %q, ptr %e)
  call void @sink(ptr %e)
  %mi = fptosi double %m to i32
  %r = call i32 @cq_measure_si32(i32 %mi)
  ret i32 %r
}
