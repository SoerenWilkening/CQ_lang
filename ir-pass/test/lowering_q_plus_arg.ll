; lowering_q_plus_arg.ll — Q+C dispatch where the classical operand is a
; function argument (not a ConstantInt). Taint-set membership selects the
; dispatch: %c is not tainted, so the add lowers to the classical-immediate
; form — and, the register being dead after the add, IN PLACE (addc).
; bd dm7f.83.1: G4 is RETIRED for a classical formal parameter. Stage 2b vouches
; for it on the pass's `!cq.classical.params` claim, which it CHECKS (every
; in-function use in a classical slot, every in-module caller classical;
; free_pairing_check.py `vouched_params`), so the site converts IN PLACE.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; CHECK:     call i32 @cqrt_alloc_i32(i32 3)
; CHECK:     call void @cqrt_addc_i32(i32 %{{[a-zA-Z0-9_.]+}}, i32 %c)
; CHECK:     call i32 @cqrt_measure_i32(
;
; CHECK-NOT: call i32 @cq_template_add_i32_hl(
; CHECK-NOT: call i32 @cq_template_add_i32(
; CHECK-NOT: cq_theta_si32
; CHECK-NOT: cq_measure_si32
; CHECK-NOT: add i32

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %c) {
entry:
  %a = call i32 @cq_theta_si32(i32 3, double 5.000000e-01)
  %d = add i32 %a, %c   ; rhs is a fn-arg classical i32
  %m = call i32 @cq_measure_si32(i32 %d)
  ret i32 %m
}
