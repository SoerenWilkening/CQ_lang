; lowering_fcmp_une_hl_f32.ll — Tainted `float != float` lowers to
; `cq_template_fcmp_une_f32_hl`. This realizes the WP1 `one→une` fix
; end-to-end: C `!=` emits `fcmp une` (not `one`), and the generated runtime
; header now ships `_une_` symbols (the `_one_` symbols are gone), so this
; tainted compare LINKS against the regenerated header (PRD §2.7,
; test_C_libtooling-7ws).
;
; One tainted handle `!=` a right-hand float literal → HL shape. Width is the
; OPERAND data width `f32`, recovered from the classical operand (`float
; 1.0`) — the handle operand is an i32-laundered theta result. The classical
; operand is passed at its real LLVM width (`float`), matching the generated
; C signature `(int32_t a_handle, float b_classical)`.
;
; The i32 flag handle flows to a measure (`cq_measure_i1` → `cqrt_measure_i1`,
; laundering the cross-type i1→i32 RAUW). The second RUN line guards the
; cross-type RAUW (risk R2).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; CHECK:     call i32 @cqrt_alloc_f32(float 2.000000e+00)
; CHECK:     call i32 @cq_template_fcmp_une_f32_hl(i32 %{{[a-zA-Z0-9_.]+}}, float 1.000000e+00)
; CHECK:     call i1 @cqrt_measure_i1(i32 %{{[a-zA-Z0-9_.]+}})
;
; The bare `fcmp` instruction must be gone, and no dead `_one_` symbol may
; appear (WP1 replaced `one` with `une`). Guard precisely so the `fcmp`
; substring inside `cq_template_fcmp_une_f32_hl` does not trip a CHECK-NOT.
; CHECK-NOT: = fcmp
; CHECK-NOT: fcmp_one
; CHECK-NOT: cq_theta_f32

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare float @cq_theta_f32(float, double)
declare i1 @cq_measure_i1(i1)

define i1 @example() {
entry:
  %a = call float @cq_theta_f32(float 2.0, double 5.000000e-01)
  ; Tainted handle `!=` a right-hand float literal → `une` `_hl`.
  %c = fcmp une float %a, 1.0
  %m = call i1 @cq_measure_i1(i1 %c)
  ret i1 %m
}
