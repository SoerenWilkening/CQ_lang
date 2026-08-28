; lowering_mc_xorc_chain.ll — CHAINED M-C in-place reassignment (bd
; test_C_libtooling-6uqc, Increment 2c): `q ^= a; q ^= b`, and the MIXED
; `q += a; q ^= b` that only exists once all three batches have landed.
;
; WHAT THE CHAIN PINS. Each link's parent is the PREVIOUS link's result, so the
; fence has to hold for a value that is itself an M-C candidate: when `%c2` is
; classified, `%c1` is still an un-lowered `BinaryOperator` and `%c1`'s only user
; IS `%c2`, so G6's "no data use after" is satisfied by the op itself (the
; `UI == bo` skip). Emission then relies on `rewriteInPlaceValueRail`'s
; `replaceAllUsesWith(Handle)`: `%c1` RAUWs to the rail handle BEFORE `%c2` is
; rewritten, so `%c2` reads the handle and not a dangling template result. One
; rail, two gates, no ancestor between them.
;
; WHAT @mixed PINS, and it is the reason this file exists in 2c rather than 2a.
; `cqrt_addc_<W>` and `cqrt_xorc_<W>` do NOT commute, so the reversal is only
; correct if the spine adjoints them in strict REVERSE PROGRAM ORDER — the xor
; first, then the add — and only if each gets ITS OWN adjoint rule (the addc
; immediate negated, the xorc immediate identical). Before 2c the two could not
; appear on one straight-line rail at all, so nothing in the tree tested that
; ordering outside the dtzb loop path.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; No out-of-place rail anywhere in this module:
; CHECK-NOT: cq_template_xor_
; CHECK-NOT: cq_template_add_

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)

; CHECK-LABEL: define void @chain
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 41)
; CHECK:      call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: call void @cqrt_xorc_i32(i32 %[[H]], i32 9)
; CHECK-NEXT: call void @cqrt_xorc_i32(i32 %[[H]], i32 3)
; reverse program order: the second gate is undone first.
; CHECK-NEXT: call void @cqrt_xorc_i32(i32 %[[H]], i32 3)
; CHECK-NEXT: call void @cqrt_xorc_i32(i32 %[[H]], i32 9)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double -5.000000e-01)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H]])
define void @chain() {
entry:
  %a  = call i32 @cq_theta_si32(i32 41, double 5.000000e-01)
  %c1 = xor i32 %a, 9
  %c2 = xor i32 %c1, 3
  ret void
}

; CHECK-LABEL: define void @mixed
; CHECK:      %[[H2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 41)
; CHECK:      call void @cqrt_ry_i32(i32 %[[H2]], double 5.000000e-01)
; CHECK-NEXT: call void @cqrt_addc_i32(i32 %[[H2]], i32 5)
; CHECK-NEXT: call void @cqrt_xorc_i32(i32 %[[H2]], i32 3)
; the xor is self-inverse; the add's immediate is NEGATED; order is reversed.
; CHECK-NEXT: call void @cqrt_xorc_i32(i32 %[[H2]], i32 3)
; CHECK-NEXT: call void @cqrt_addc_i32(i32 %[[H2]], i32 -5)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H2]], double -5.000000e-01)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H2]])
define void @mixed() {
entry:
  %a  = call i32 @cq_theta_si32(i32 41, double 5.000000e-01)
  %c1 = add i32 %a, 5
  %c2 = xor i32 %c1, 3
  ret void
}
