; lowering_mc_xorc_commuted.ll — M-C in-place `xor` with the IMMEDIATE ON THE
; LEFT (bd test_C_libtooling-6uqc, Increment 2c).
;
; `c ^ q` and `q ^ c` are the same permutation, so both convert. This is the ONE
; structural difference between 2c and 2b and it is worth a fixture rather than a
; comment: Inc 2b's `sub` had to be DIRECTIONAL (`q - c` converts, `c - q` never
; does — it is negate-the-RAIL then add, which `cqrt_addc_<W>` cannot express at
; any width, pinned by lowering_mc_sub_fence_fallback.ll's `@classical_lhs`).
; `xor` carries NO such rule, and the reason is exactly that it commutes: the
; shared shape predicate `inPlaceValueRailOperand` returns "the one tainted
; operand" without regard to position, and the emitter then puts that operand in
; the handle slot and the other in the immediate slot. So a `c ^ q` that the
; out-of-place path would have lowered to `cq_template_xor_i32_hl` (the
; commutativity canonicalization already moves the literal right) is here
; lowered in place, with no `_lh` form anywhere in the M-C surface.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 41)
; CHECK:     call void @cqrt_xorc_i32(i32 %[[H]], i32 99)
; CHECK:     call void @cqrt_xorc_i32(i32 %[[H]], i32 99)
; CHECK:     call void @cqrt_free(i32 %[[H]])
;
; CHECK-NOT: cq_template_xor_

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)

define void @example() {
entry:
  %a = call i32 @cq_theta_si32(i32 41, double 5.000000e-01)
  %c = xor i32 99, %a        ; LITERAL ON THE LEFT -> still in place
  ret void
}
