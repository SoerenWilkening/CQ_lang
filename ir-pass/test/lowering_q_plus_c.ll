; lowering_q_plus_c.ll — Mixed-operand Q+C dispatch. A tainted add whose
; rhs is a ConstantInt lowers to cq_template_add_i32_hl(handle, literal).
; Also covers the lhs-constant case where the pass swaps operands so the
; handle is always first.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; CHECK:     call i32 @cqrt_alloc_i32(i32 3)
; CHECK:     call i32 @cq_template_add_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 5)
; CHECK:     call i32 @cq_template_add_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 7)
; CHECK:     call i32 @cqrt_measure_i32(
;
; CHECK-NOT: call i32 @cq_template_add_i32(
; CHECK-NOT: cq_theta_si32
; CHECK-NOT: cq_measure_si32
; CHECK-NOT: add i32

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example() {
entry:
  %a = call i32 @cq_theta_si32(i32 3, double 5.000000e-01)
  %d = add i32 %a, 5    ; rhs constant
  %e = add i32 7, %d    ; lhs constant; expect swap
  %m = call i32 @cq_measure_si32(i32 %e)
  ret i32 %m
}
