; cq-0umd (166, rules 18, 6): the fields of a clone call's composite result are undone together by the
; call's twin (U2); rule 6 never cleans one of them in place (it stopped with "cleanupBijective of a
; merged handle"). The add is out of place and the twin follows it.
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"
; CHECK top: call i32 @cq_template_add_i32(i32 %{{b}}, i32 %{{a}})
; CHECK top: call void @__cq_q_mk_10_unc(
; CHECK-COUNT top: cqrt_copy 0
define i32 @top(i32 %x0, double %th, i32 %c) {
  %x = tail call i32 @cq_theta_si32(i32 %x0, double %th)
  %r = tail call { i32, i32 } @mk(i32 %x, i32 %c)
  %a = extractvalue { i32, i32 } %r, 0
  %b = extractvalue { i32, i32 } %r, 1
  %s = add i32 %b, %a
  %m = tail call i32 @cq_measure_si32(i32 %s)
  ret i32 %m
}
define internal { i32, i32 } @mk(i32 %x, i32 %c) noinline {
  %a = add i32 %x, %c
  %b = mul i32 %x, %c
  %1 = insertvalue { i32, i32 } poison, i32 %a, 0
  %2 = insertvalue { i32, i32 } %1, i32 %b, 1
  ret { i32, i32 } %2
}
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
