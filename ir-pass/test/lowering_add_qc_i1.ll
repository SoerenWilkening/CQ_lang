; lowering_add_qc_i1.ll — Per-width Q+C add for the i1 ABI (M16). One
; tainted `qbool_mid_t` handle, one literal `true` flow through `add i1`
; and must lower to `cq_template_add_i1_hl(handle, classical)`. Taint-
; set non-membership selects the `_hl` dispatch.

; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -

; CHECK:     call i32 @cqrt_alloc_i1(i1 false)
; CHECK:     call i32 @cq_template_add_i1_hl(i32 %{{[a-zA-Z0-9_.]+}}, i1 true)

; CHECK-NOT: call i32 @cq_template_add_i1(i32 %{{.*}}, i32
; CHECK-NOT: cq_init_i1
; CHECK-NOT: add i1

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

%qbool_mid_t = type { i1 }

declare %qbool_mid_t @cq_init_i1(i1)

define void @example() {
entry:
  %a_struct = call %qbool_mid_t @cq_init_i1(i1 false)
  %a        = extractvalue %qbool_mid_t %a_struct, 0

  %c        = add i1 %a, true
  ret void
}
