; lowering_shl_lh_i32.ll — Bitwise `shl` with a literal on the left
; (`3 << x`). `shl` is non-commutative, so a left literal lowers to the
; `_lh` shape `cq_template_shl_i32_lh(classical, handle)` with operand
; order preserved (PRD §2.6 — every `3 << x` survives `-O1` as `shl …_lh`).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; CHECK:     call i32 @cqrt_alloc_i32(i32 5)
; CHECK:     call i32 @cq_template_shl_i32_lh(i32 3, i32 %{{[a-zA-Z0-9_.]+}})
;
; CHECK-NOT: call i32 @cq_template_shl_i32_hl(
; CHECK-NOT: cq_theta_si32
; CHECK-NOT: shl i32

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)

define void @example() {
entry:
  %a = call i32 @cq_theta_si32(i32 5, double 5.000000e-01)
  %c = shl i32 3, %a            ; 3 << x → _lh
  ret void
}
