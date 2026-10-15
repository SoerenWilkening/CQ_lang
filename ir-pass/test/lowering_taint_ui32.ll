; lowering_taint_ui32.ll — Pins that @cq_theta_ui32 is recognized as a taint
; source identically to @cq_theta_si32 (ui32 shares the i32 ABI). Same shape
; as lowering_basic.ll, differing only in the front-end suffix.
;
; bd r2j3.33 R11 round 1 (ruling-dm7f51-both-dead-loud-2026-10-15): with BOTH
; operands dead the overwritten register is not recoverable from SSA and the
; pass fails loudly (pinned by lowering_inplace_qq_decline_both_dead.ll). This
; fixture's subject is not that question, so `%a` is kept LIVE by a second
; measurement; the add then lowers in place on `%b`'s rail.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; CHECK:     call i32 @cqrt_alloc_i32(i32 3)
; CHECK:     call i32 @cqrt_alloc_i32(i32 5)
; bd r2j3.33 (dm7f.51 step 1): both operands' old values are dead and the sum
; is measured, so the Q+Q add now lowers IN PLACE (`cqrt_add_i32(src, dst)`,
; tagged `!cq.inplace.qq`) instead of minting `cq_template_add_i32` beside a
; kept old register.
; CHECK:     call void @cqrt_add_i32({{.*}}), !cq.inplace.qq
; CHECK:     call i32 @cqrt_measure_i32(
;
; CHECK-NOT: cq_theta_ui32
; CHECK-NOT: cq_measure_ui32
; CHECK-NOT: add i32

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_ui32(i32, double)
declare i32 @cq_measure_ui32(i32)

define i32 @example() {
entry:
  %a = call i32 @cq_theta_ui32(i32 3, double 5.000000e-01)
  %b = call i32 @cq_theta_ui32(i32 5, double 5.000000e-01)
  %c = add i32 %a, %b
  %m = call i32 @cq_measure_ui32(i32 %c)
  %ma = call i32 @cq_measure_ui32(i32 %a)
  ret i32 %m
}
