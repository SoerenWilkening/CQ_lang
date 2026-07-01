; lowering_reject_byref_wrong_sig.ll — bd g387 Rule-13 regression (DEFECT A/B).
; A by-ref-NAMED (frexp/modf/remquo) tainted call with a NON-STANDARD signature
; must LOUD-DECLINE, never (A) survive as a verify-clean classical call reading a
; quantum handle [silent miscompile], nor (B) crash the backend with a broken
; module. The `isByRefMathCall` escape carve is name-only, so lowerByRefMath OWNS
; the decline for any name-matched TAINTED call it cannot lower. Here `@frexp` is
; declared returning i32 (real frexp returns fp) with a tainted i32 operand — the
; original silent-miscompile shape.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
;
; CHECK: cq by-ref math out-param under quantum lift (unsupported by-ref math signature)

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @frexp(i32, ptr)   ; WRONG: real frexp is `double frexp(double, int*)`

define i32 @ex(i32 %0) {
entry:
  %cell = alloca i32, align 4
  %q = call i32 @cq_theta_si32(i32 %0, double 5.000000e-01)
  %r = call i32 @frexp(i32 %q, ptr %cell)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
