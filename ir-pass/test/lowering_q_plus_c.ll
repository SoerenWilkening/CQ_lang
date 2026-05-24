; lowering_q_plus_c.ll — Mixed-operand Q+C dispatch. A tainted add whose
; rhs is an LLVM ConstantInt lowers to cq_template_add_i32_hl (handle,
; literal). Also covers the lhs-constant case where the IR pass swaps
; operands so the handle is always first. Spec: PLAN.md §4.7.1 / §6.3.

; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -

; CHECK:     call i32 @cqrt_alloc_classical_i32(i32 3)
; CHECK:     call i32 @cq_template_add_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 5)
; CHECK:     call i32 @cq_template_add_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 7)
; CHECK:     call i32 @cqrt_measure_i32(

; CHECK-NOT: call i32 @cq_template_add_i32(
; CHECK-NOT: cq_init_i32
; CHECK-NOT: cq_measure_i32{{[^_]}}
; CHECK-NOT: extractvalue
; CHECK-NOT: insertvalue
; CHECK-NOT: add i32

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

%qint_mid_t = type { i32 }

declare %qint_mid_t @cq_init_i32(i32)
declare i32         @cq_measure_i32(%qint_mid_t)

; Two tainted adds — one with constant on rhs (canonical), one with
; constant on lhs (forces the IR pass's swap path). Both must dispatch
; to cq_template_add_i32_hl with the handle as the first arg.
define i32 @example() {
entry:
  %a_struct = call %qint_mid_t @cq_init_i32(i32 3)
  %a        = extractvalue %qint_mid_t %a_struct, 0

  %d        = add i32 %a, 5    ; rhs is constant
  %e        = add i32 7, %d    ; lhs is constant; expect swap

  %e_struct = insertvalue %qint_mid_t poison, i32 %e, 0
  %m        = call i32 @cq_measure_i32(%qint_mid_t %e_struct)

  ret i32 %m
}
