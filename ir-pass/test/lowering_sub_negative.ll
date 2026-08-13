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
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
;
; CHECK:     call i32 @cqrt_alloc_i32(i32 3)
; CHECK:     call i32 @cq_template_sub_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 5)
;
; CHECK-NOT: call i32 @cq_template_sub_i32_lh(
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
  ret void
}
