; lowering_q_plus_arg.ll — Q+C dispatch where the classical operand is
; a function argument (not an LLVM ConstantInt). Taint-set membership
; is what selects the dispatch — `%c` is not tainted, so `add i32
; %a_handle, %c` lowers to `cq_template_add_i32_hl(handle, classical)`
; just as it would for a literal constant. Pins the broader-than-
; ConstantInt dispatch rule from test_C_libtooling-9os.

; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -

; CHECK:     call i32 @cqrt_alloc_classical_i32(i32 3)
; CHECK:     call i32 @cq_template_add_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 %c)
; CHECK:     call i32 @cqrt_measure_i32(

; CHECK-NOT: call i32 @cq_template_add_i32(
; CHECK-NOT: cq_init_i32
; CHECK-NOT: cq_measure_i32{{[^_]}}
; CHECK-NOT: add i32

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

%qint_mid_t = type { i32 }

declare %qint_mid_t @cq_init_i32(i32)
declare i32         @cq_measure_i32(%qint_mid_t)

define i32 @example(i32 %c) {
entry:
  %a_struct = call %qint_mid_t @cq_init_i32(i32 3)
  %a        = extractvalue %qint_mid_t %a_struct, 0

  %d        = add i32 %a, %c   ; rhs is a fn-arg classical i32

  %d_struct = insertvalue %qint_mid_t poison, i32 %d, 0
  %m        = call i32 @cq_measure_i32(%qint_mid_t %d_struct)

  ret i32 %m
}
