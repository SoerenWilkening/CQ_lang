; lowering_icmp_flip_hl_i32.ll — Literal-on-left compare canonicalizes by
; PREDICATE FLIP (PRD §2.4). `5 < x` (literal on the LHS) becomes `x > 5`:
; the handle moves to the left and the predicate flips slt→sgt, reusing the
; `_hl` template — there are NO `_lh` compare templates. So this must emit
; `cq_template_icmp_sgt_i32_hl(handle, 5)` (CHECK the flipped `sgt`; CHECK-NOT
; the un-flipped `slt` or any `_lh`).
;
; The i32 flag handle flows to a measure (`cq_measure_i1` → `cqrt_measure_i1`,
; which launders the cross-type i1→i32 RAUW by erasing the intrinsic call).
; The second RUN line guards the cross-type RAUW (risk R2).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
;
; CHECK:     call i32 @cqrt_alloc_i32(i32 3)
; CHECK:     call i32 @cq_template_icmp_sgt_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 5)
; CHECK:     call i1 @cqrt_measure_i1(i32 %{{[a-zA-Z0-9_.]+}})
;
; The bare `icmp` instruction must be gone; the UN-flipped `slt` template and
; any `_lh` compare template must never appear. Guard precisely so the
; `icmp` substring inside `cq_template_icmp_sgt_i32_hl` does not trip a
; CHECK-NOT.
; CHECK-NOT: = icmp
; CHECK-NOT: icmp_slt
; CHECK-NOT: _i32_lh
; CHECK-NOT: cq_theta_si32

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i1 @cq_measure_i1(i1)

define i1 @example() {
entry:
  %a = call i32 @cq_theta_si32(i32 3, double 5.000000e-01)
  ; Literal on the LEFT: `5 < x` ⇒ predicate flip ⇒ `x > 5` → `sgt` `_hl`.
  %c = icmp slt i32 5, %a
  %m = call i1 @cq_measure_i1(i1 %c)
  ret i1 %m
}
