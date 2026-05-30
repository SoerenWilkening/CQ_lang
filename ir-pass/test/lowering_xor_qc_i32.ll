; lowering_xor_qc_i32.ll — Bitwise `xor` (commutative) with the literal on
; the LEFT in source. Because `xor` is commutative the literal
; canonicalizes to the RHS → `cq_template_xor_i32_hl(handle, classical)`
; (handle-on-left HL), proving the commutative swap fires regardless of
; which source side held the classical operand (PRD §2.4).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; CHECK:     call i32 @cqrt_alloc_i32(i32 8)
; CHECK:     call i32 @cq_template_xor_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 12)
;
; CHECK-NOT: call i32 @cq_template_xor_i32_lh(
; CHECK-NOT: call i32 @cq_template_xor_i32(i32 %{{.*}}, i32 %
; CHECK-NOT: cq_theta_si32
; CHECK-NOT: xor i32

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)

define void @example() {
entry:
  %a = call i32 @cq_theta_si32(i32 8, double 5.000000e-01)
  %c = xor i32 12, %a           ; literal on left; commutative → _hl(handle, 12)
  ret void
}
