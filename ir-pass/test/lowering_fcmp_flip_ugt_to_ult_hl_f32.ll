; lowering_fcmp_flip_ugt_to_ult_hl_f32.ll — 8rvn (Phase 7.1 iw81.4 §4.4):
; operand-swap CLOSURE of the new unordered predicates. There are no `_lh`
; compare templates, so a CLASSICAL-on-left compare is canonicalized by
; `flipPredicate`/`getSwappedPredicate` to handle-on-left `_hl`. For the new
; unordered twins this maps `ugt <-> ult` and `uge <-> ule` — BOTH halves are in
; the curated set, so the flip never moves an in-scope predicate out of scope
; (the invariant `compareInScope`/CompareLowering rely on; one/ord/uno/ueq/oeq/
; une self-map).
;
; Here `fcmp ugt float 1.0, %a` (classical LEFT, handle RIGHT) flips to handle-
; left `ult`, lowering to `cq_template_fcmp_ult_f32_hl` — NOT a phantom `ugt`
; symbol with swapped operands, and NOT any `_lh` form.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; CHECK:     call i32 @cqrt_alloc_f32(float 2.000000e+00)
; CHECK:     call i32 @cq_template_fcmp_ult_f32_hl(i32 %{{[a-zA-Z0-9_.]+}}, float 1.000000e+00)
; CHECK:     call i1 @cqrt_measure_i1(i32 %{{[a-zA-Z0-9_.]+}})
;
; CHECK-NOT: = fcmp
; The flipped form is `ult`, never a swapped-operand `ugt` symbol or an `_lh` form.
; CHECK-NOT: cq_template_fcmp_ugt
; CHECK-NOT: _f32_lh(

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare float @cq_theta_f32(float, double)
declare i1 @cq_measure_i1(i1)

define i1 @example() {
entry:
  %a = call float @cq_theta_f32(float 2.0, double 5.000000e-01)
  ; Classical literal on the LEFT, tainted handle on the RIGHT → predicate flip.
  %c = fcmp ugt float 1.0, %a
  %m = call i1 @cq_measure_i1(i1 %c)
  ret i1 %m
}
