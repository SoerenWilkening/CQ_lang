; cq-tigu (owner ruling cq-r6bc): rule 2 collapses the fenv state in a measured value's cone, even when it
; was computed before the measurement. f: the mode rail select(y > k, FE_UPWARD, host mode) becomes
; classical at cq_measure(y): it is uncomputed (no output) and written back by fesetround. g: the flags
; rail select(y > k, FE_INEXACT, 0) is written back by feraiseexcept. h: the flags rail depends on x,
; which is never measured: it stays the final flags rail (kept), no write-back.
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"
define double @f(double %x0, double %th, double %c, double %k) {
entry:
  %x = call double @cq_theta_f64(double %x0, double %th)
  %y = fmul double %x, %c
  %p = fcmp ogt double %y, %k
  br i1 %p, label %t, label %j
t:
  %r = call i32 @fesetround(i32 2048)
  br label %j
j:
  %m = call double @cq_measure_f64(double %y)
  ret double %m
}
define double @g(double %x0, double %th, double %c, double %k) {
entry:
  %x = call double @cq_theta_f64(double %x0, double %th)
  %y = fmul double %x, %c
  %p = fcmp ogt double %y, %k
  br i1 %p, label %t, label %j
t:
  %r = call i32 @feraiseexcept(i32 32)
  br label %j
j:
  %m = call double @cq_measure_f64(double %y)
  ret double %m
}
define double @h(double %x0, double %th, double %c, double %k) {
entry:
  %x = call double @cq_theta_f64(double %x0, double %th)
  %y = fmul double %x, %c
  %p = fcmp ogt double %x, %k
  br i1 %p, label %t, label %j
t:
  %r = call i32 @feraiseexcept(i32 32)
  br label %j
j:
  %m = call double @cq_measure_f64(double %y)
  ret double %m
}
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare i32 @fesetround(i32)
declare i32 @feraiseexcept(i32)
; CHECK f: call i32 @fegetround()
; CHECK f: call i32 @cq_template_select_i32_ll(
; CHECK f: call void @cq_template_select_i32_ll_unc(
; CHECK f: call i32 @fesetround(i32 %{{v}})
; CHECK g: call void @cq_template_select_i32_ll_unc(
; CHECK g: call i32 @feraiseexcept(i32 %{{v}})
; CHECK-COUNT h: @cq_template_select_i32_ll_unc( 0
; CHECK-COUNT h: @feraiseexcept( 0
