; lowering_sub_negative.ll — Repinned in Phase 3 (WP3). This file used to
; pin the "no template for opcode 'sub i32'" diagnostic, back when `sub`
; was out of scope. `sub` now lowers, so the fixture asserts the REAL
; lowering instead: a tainted handle minus a right-hand literal is the
; non-commutative handle-on-left HL shape →
; `cq_template_sub_i32_hl(handle, classical)` (source operand order
; preserved — `sub` is non-commutative, so no BirthOrder/canonicalization
; swap). The companion literal-on-left case lives in
; lowering_sub_lh_i32.ll.
;
; THIS IS ALSO THE M-C FENCE-FALLBACK PIN FOR `sub` AT i32 (bd
; test_C_libtooling-6uqc, Increment 2b — the exact treatment 2a gave
; lowering_add_qc_i32.ll, and for the same measured reason). Since 2b a `q - c`
; whose parent handle is DEAD AFTER the op lowers IN PLACE to
; `cqrt_addc_i32(handle, -c)` instead — see lowering_mc_subc_i32.ll, the positive
; twin. The SECOND sub below is what keeps both sites out of place, and it is the
; boundary this file exists to hold:
;   * for `%c`, `%d` is a data use of `%a` AFTER it            -> G6 refuses;
;   * for `%d`, `%c` is a PRIOR use but it is a still-unlowered tainted opcode
;     the Phase-5 spine will adjoint later (reading `%a`)      -> G7 refuses.
; So a fan-out parent NEVER converts, at any opcode. Deleting the second sub
; would silently move this file to the in-place stream and take the out-of-place
; `_hl` OPERAND-ORDER assertion with it — the one property this file and
; lowering_sub_lh_i32.ll exist as a pair to pin.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; CHECK:     call i32 @cqrt_alloc_i32(i32 3)
; CHECK:     call i32 @cq_template_sub_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 5)
; CHECK:     call i32 @cq_template_sub_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 7)
;
; CHECK-NOT: call i32 @cq_template_sub_i32_lh(
; CHECK-NOT: cqrt_addc_
; CHECK-NOT: cq_theta_si32
; CHECK-NOT: sub i32

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)

define void @example() {
entry:
  %a = call i32 @cq_theta_si32(i32 3, double 5.000000e-01)
  ; Tainted handle minus a right-hand literal → `_hl`, operand order kept.
  %c = sub i32 %a, 5
  %d = sub i32 %a, 7    ; fan-out: BOTH sites stay out of place
  ret void
}
