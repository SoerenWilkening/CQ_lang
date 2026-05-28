; lowering_add_qc_i16.ll — Per-width Q+C add for the i16 ABI. One
; tainted `qshort_mid_t` handle, one i16 literal flow through `add i16`
; and must lower to `cq_template_add_i16_hl(handle, classical)`.

; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -

; CHECK:     call i32 @cqrt_alloc_i16(i16 17)
; CHECK:     call i32 @cq_template_add_i16_hl(i32 %{{[a-zA-Z0-9_.]+}}, i16 100)

; CHECK-NOT: call i32 @cq_template_add_i16(i32 %{{.*}}, i32
; CHECK-NOT: cq_init_si16
; CHECK-NOT: add i16

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

%qshort_mid_t = type { i16 }

declare %qshort_mid_t @cq_init_si16(i16)

define void @example() {
entry:
  %a_struct = call %qshort_mid_t @cq_init_si16(i16 17)
  %a        = extractvalue %qshort_mid_t %a_struct, 0

  %c        = add i16 %a, 100
  ret void
}
