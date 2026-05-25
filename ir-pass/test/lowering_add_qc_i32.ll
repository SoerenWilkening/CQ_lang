; lowering_add_qc_i32.ll — Per-width Q+C add for the i32 ABI (M16). One
; tainted `qint_mid_t` handle, one i32 literal flow through `add i32`
; and lower to `cq_template_add_i32_hl(handle, classical)`. The Phase 1
; baseline; `lowering_q_plus_c.ll` covers the full chain through
; measure plus the lhs-constant swap path, while this fixture isolates
; the per-width add lowering.
;
; Spec: phases/phase2/PLAN.md §4.16.

; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -

; CHECK:     call i32 @cqrt_alloc_i32(i32 41)
; CHECK:     call i32 @cq_template_add_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 99)

; CHECK-NOT: call i32 @cq_template_add_i32(i32 %{{.*}}, i32 %
; CHECK-NOT: cq_init_si32
; CHECK-NOT: add i32

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

%qint_mid_t = type { i32 }

declare %qint_mid_t @cq_init_si32(i32)

define void @example() {
entry:
  %a_struct = call %qint_mid_t @cq_init_si32(i32 41)
  %a        = extractvalue %qint_mid_t %a_struct, 0

  %c        = add i32 %a, 99
  ret void
}
