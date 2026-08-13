; lowering_intrinsic_usub_sat_lh_i32.ll — Phase 7.1 Increment E: Class-2 binary,
; NON-commutative (usub.sat: a-b saturated != b-a saturated), literal-on-left.
; `@llvm.usub.sat.i32(100, handle)` lowers to `cq_template_usub_sat_i32_lh(i32
; 100, handle)` — the `_lh` shape (classical on left, handle on right), order
; preserved (operand order is semantic for a non-commutative op). Pins that the
; saturating sub family carries the lh shape that the commutative min/max/add.sat
; do not.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; CHECK:     call i32 @cqrt_alloc_i32(i32 %u)
; CHECK:     call i32 @cq_template_usub_sat_i32_lh(i32 100, i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call i32 @cqrt_measure_i32(i32 %{{[a-zA-Z0-9_.]+}})
;
; CHECK-NOT: @llvm.usub.sat
; CHECK-NOT: cq_template_usub_sat_i32_hl(

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @llvm.usub.sat.i32(i32, i32)

define i32 @example(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %r = call i32 @llvm.usub.sat.i32(i32 100, i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
