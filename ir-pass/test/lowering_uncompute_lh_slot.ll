; lowering_uncompute_lh_slot.ll — Phase 5 WI-3 DD-3 slot-mapping lock for the
; `_lh` shape (literal-on-the-LEFT, handle-on-the-right). The `_hl` goldens cannot
; exercise this; the void `_unc` emitter is shape-agnostic (it prepends `out` and
; copies the forward operands in their ORIGINAL order, EmitInverse.cpp), so a `_lh`
; forward `cq_template_sub_i32_lh(lit, h)` must adjoint to
; `cq_template_sub_i32_lh_unc(out, lit, h)` — the classical literal STAYS in the
; forward slot, the handle STAYS in the forward slot, `out` (the forward result) is
; prepended. A swapped slot here is a verify-clean WRONG UNITARY; this pins it.
;
; `q = cq_theta; q = 100 - q` — a dead single-register `_lh` terminal.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
;
; Forward `_lh` (literal at slot 0, handle at slot 1):
; CHECK:     call void @cqrt_ry_i32(i32 %[[H:[a-zA-Z0-9_.]+]], double 2.500000e-01)
; CHECK:     %[[D:[a-zA-Z0-9_.]+]] = call i32 @cq_template_sub_i32_lh(i32 100, i32 %[[H]])
; Reversed adjoint: void `_unc(out=%d, lit=100, src=%h)` — DD-3 slots preserved,
; reading the still-live root %h; then free the |0> root.
; CHECK:     call void @cq_template_sub_i32_lh_unc(i32 %[[D]], i32 100, i32 %[[H]])
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double -2.500000e-01)
; CHECK:     call void @cqrt_free(i32 %[[H]])
;
; CHECK-NOT: cq_template_sub_i32_lh_inv
; CHECK-NOT: cq_theta_si32
;
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)

define void @slice(i32 %x) {
entry:
  %q = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  %d = sub i32 100, %q                           ; lit - q => _lh, dead terminal
  ret void
}
