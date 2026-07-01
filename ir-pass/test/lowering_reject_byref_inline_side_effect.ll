; lowering_reject_byref_inline_side_effect.ll — bd g7ip MISS-SAFETY probe. A
; visible by-ref producer whose body has an EXTRA side-effecting call
; (`sideeffect()`) besides the single out-store. Inlining ONLY the store value
; would DROP that call — a verify-clean SILENT MISCOMPILE. ByRefInline's body
; proof is TOTAL (every block instruction must be the store / a pure value op /
; lifetime-dbg), so it SKIPS this shape (accept-only); the call then falls through
; to the EXISTING loud specializer decline. Over-declining is safe; over-accepting
; is the one unforgivable bug (Prime Directive).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
;
; CHECK: cq specialization: callee contains a non-reversibilizable construct under quantum lift (nested call)

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"

define i32 @demo() {
  %cell = alloca i32, align 4
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  call void @mysplit(i32 %q, ptr %cell)
  %r = load i32, ptr %cell, align 4
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

define internal void @mysplit(i32 %v, ptr %out) {
  call void @sideeffect()
  %r = add nsw i32 %v, 7
  store i32 %r, ptr %out, align 4
  ret void
}

declare void @sideeffect()
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
