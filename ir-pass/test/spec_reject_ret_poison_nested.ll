; spec_reject_ret_poison_nested.ll — DECLINE (bd 3p2a).
; ARM: the TRANSITIVE reach of the fence — `scanBody` recurses into every nested
; visible callee, so an inner poison-returning body is adjudicated in its OWN
; frame and the fence needs no traversal of its own.
;
; The walk in `returnDerivesFromUndef` deliberately STOPS at a call result: it
; descends through an `Instruction`'s operands (a call's arguments included) but
; never enters a callee's BODY, because a `Function` is not an `Instruction`. That
; would be a hole if `scanBody` did not already recurse — this file is the
; measurement that it does. `@outer`'s own return cone is `add %t, %u`, which is
; clean; the decline comes from the `@inner` frame and names `@inner`.
;
; WHY THIS SHAPE MATTERS MORE THAN THE FLAT ONE. It is the exact shape whose
; TWINNED form is the measured bd xy9n miscompile: make `@outer` itself an inner
; call (one more level) and `synthUncomputeTwin` duplicates the whole body
; VERBATIM, so the call to the poison-returning clone is executed TWICE and the
; adjoint can invert a different addend than the forward computed — dirty rail,
; and the `cqrt_free` that follows is a hidden measurement (Rules 6, 8). That
; three-level probe was measured ON THE PRE-CHANGE PLUGIN to decline there, at
; `findUndefOperandInBody`; this fence moves the decline to the accept predicate,
; where the certificate is issued, instead of leaving it to a fence at the
; duplication site.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq specialization: callee return value denotes no value (undef/poison)

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @inner(i32 %a) {
entry:
  ret i32 poison
}

define i32 @outer(i32 %t) {
entry:
  %u = call i32 @inner(i32 %t)
  %r = add i32 %t, %u           ; a CLEAN return cone — the walk stops at %u
  ret i32 %r
}

define void @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %s = call i32 @outer(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %s)
  ret void
}
