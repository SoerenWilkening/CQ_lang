; lowering_sub_lh_i32.ll — Literal-on-left `sub` (non-commutative) →
; `_lh`. `100 - x` keeps a literal on the LHS and a handle on the RHS;
; because `sub` is non-commutative the operand order is semantic and must
; be preserved, so this lowers to the distinct
; `cq_template_sub_i32_lh(classical, handle)` template (NOT `_hl`, NOT a
; predicate/operand swap). This is the canonical `_lh` shape from PRD §2.6.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; CHECK:     call i32 @cqrt_alloc_i32(i32 4)
; CHECK:     call i32 @cq_template_sub_i32_lh(i32 100, i32 %{{[a-zA-Z0-9_.]+}})
;
; CHECK-NOT: call i32 @cq_template_sub_i32_hl(
; CHECK-NOT: cq_theta_si32
; CHECK-NOT: sub i32

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)

define void @example() {
entry:
  %a = call i32 @cq_theta_si32(i32 4, double 5.000000e-01)
  %c = sub i32 100, %a          ; 100 - x → _lh
  ret void
}
