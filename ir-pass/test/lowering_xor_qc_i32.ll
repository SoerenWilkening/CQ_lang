; lowering_xor_qc_i32.ll — Bitwise `xor` (commutative) with the literal on
; the LEFT in source, OUT OF PLACE. Because `xor` is commutative the literal
; canonicalizes to the RHS → `cq_template_xor_i32_hl(handle, classical)`
; (handle-on-left HL), proving the commutative swap fires regardless of
; which source side held the classical operand (PRD §2.4).
;
; THIS IS ALSO THE M-C FENCE-FALLBACK PIN FOR `xor` (bd test_C_libtooling-6uqc,
; Increment 2c) — the exact re-disposition Increment 2a applied to
; lowering_add_qc_i{1,8,16,32,64}.ll, for the same reason and by the same edit.
; Since 2c, a `q ^ c` whose parent handle is DEAD AFTER the op lowers IN PLACE to
; `cqrt_xorc_i32` instead (lowering_mc_xorc_i32.ll is the positive twin, and
; lowering_mc_xorc_commuted.ll pins that the literal-on-LEFT spelling below is
; among the shapes that convert). The SECOND xor here is what keeps both sites
; out of place, and it is the boundary this file exists to hold:
;   * for `%c`, `%d` is a data use of `%a` AFTER it            -> G6 refuses;
;   * for `%d`, `%c` is a PRIOR use but it is a still-unlowered tainted opcode
;     the Phase-5 spine will adjoint later (reading `%a`)      -> G7 refuses.
; So a fan-out parent NEVER converts, at any width or opcode. Deleting the
; second xor would silently move this file to the in-place stream and take the
; commutative-canonicalization assertion — the thing it was written for — with
; it.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; CHECK:     call i32 @cqrt_alloc_i32(i32 8)
; CHECK:     call i32 @cq_template_xor_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 12)
; CHECK:     call i32 @cq_template_xor_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 7)
;
; CHECK-NOT: call i32 @cq_template_xor_i32_lh(
; CHECK-NOT: call i32 @cq_template_xor_i32(i32 %{{.*}}, i32 %
; CHECK-NOT: cqrt_xorc_
; CHECK-NOT: cq_theta_si32
; CHECK-NOT: xor i32

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)

define void @example() {
entry:
  %a = call i32 @cq_theta_si32(i32 8, double 5.000000e-01)
  %c = xor i32 12, %a           ; literal on left; commutative → _hl(handle, 12)
  %d = xor i32 %a, 7            ; fan-out: BOTH sites stay out of place
  ret void
}
