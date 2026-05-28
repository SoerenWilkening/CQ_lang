; lowering_add_qc_i8.ll — Per-width Q+C add for the i8 ABI. One
; tainted `qschar_mid_t` handle, one i8 literal flow through `add i8`
; and must lower to `cq_template_add_i8_hl(handle, classical)`.

; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -

; CHECK:     call i32 @cqrt_alloc_i8(i8 7)
; CHECK:     call i32 @cq_template_add_i8_hl(i32 %{{[a-zA-Z0-9_.]+}}, i8 42)

; CHECK-NOT: call i32 @cq_template_add_i8(i32 %{{.*}}, i32
; CHECK-NOT: cq_init_si8
; CHECK-NOT: add i8

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

%qschar_mid_t = type { i8 }

declare %qschar_mid_t @cq_init_si8(i8)

define void @example() {
entry:
  %a_struct = call %qschar_mid_t @cq_init_si8(i8 7)
  %a        = extractvalue %qschar_mid_t %a_struct, 0

  %c        = add i8 %a, 42
  ret void
}
