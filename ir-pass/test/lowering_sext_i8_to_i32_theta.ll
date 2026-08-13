; lowering_sext_i8_to_i32_theta.ll — Phase 7.1 Increment D core cast fix: a cast
; directly off a tainted THETA handle recovers its LOGICAL source width from
; HandleWidth. RotationLowering RAUWs the i8 theta result to its i32 alloc handle
; BEFORE lowerOps captures the sext's getSrcTy(), so a live read would yield i32
; (→ the garbage `sext_i32_to_i32`, no template, decline). The fix reads the i8
; width recorded at the theta mint and emits `cq_template_sext_i8_to_i32`. This
; pins the cast-fix's NEW branch for the NON-fp case (the f16 fpext fixture pins
; the fp case); the sibling lowering_sext_i8_to_i32.ll casts off a trunc result
; (a Phase-2 sibling, captured from getSrcTy) and does NOT exercise this branch.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
;
; CHECK:     call i32 @cqrt_alloc_i8(i8 7)
; CHECK:     call i32 @cq_template_sext_i8_to_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call i32 @cqrt_measure_i32(i32 %{{[a-zA-Z0-9_.]+}})
;
; The laundered-i32 width must NOT be used (no _i32_to_i32 garbage symbol).
; CHECK-NOT: cq_template_sext_i32_to_i32
; CHECK-NOT: = sext
; CHECK-NOT: cq_theta_si8

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i8 @cq_theta_si8(i8, double)
declare i32 @cq_measure_si32(i32)

define i32 @example() {
entry:
  %a = call i8 @cq_theta_si8(i8 7, double 5.000000e-01)
  %w = sext i8 %a to i32
  %m = call i32 @cq_measure_si32(i32 %w)
  ret i32 %m
}
