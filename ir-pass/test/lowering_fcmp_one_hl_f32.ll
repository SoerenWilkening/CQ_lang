; lowering_fcmp_one_hl_f32.ll — 8rvn (Phase 7.1 iw81.4 §4.4): the FLIP of the
; former `lowering_fcmp_one_negative.ll`. `fcmp one` (ordered-not-equal) is now
; IN the curated fcmp predicate set (YAML `predicates.fcmp` + the
; `compareInScope` mirror), so a tainted data-position `one` compare lowers to
; the generated `cq_template_fcmp_one_f32_hl` template instead of loud-declining.
;
; Before 8rvn this exact module declined (`no template for opcode 'fcmp …'`) —
; the ziov4 predicate-scope gate. 8rvn ships the `one` template across the
; fwd/inv/unc × qq/hl grid at f16/f32/f64, so it now ACCEPTS and LINKS.
;
; One tainted handle `one` a right-hand float literal → HL shape. Width is the
; OPERAND data width `f32`, recovered from the classical operand (`float 1.0`).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; CHECK:     call i32 @cqrt_alloc_f32(float 2.000000e+00)
; CHECK:     call i32 @cq_template_fcmp_one_f32_hl(i32 %{{[a-zA-Z0-9_.]+}}, float 1.000000e+00)
; CHECK:     call i1 @cqrt_measure_i1(i32 %{{[a-zA-Z0-9_.]+}})
;
; The bare `fcmp` must be gone; the result is the i32 flag handle, never an i1.
; Guard precisely so the `fcmp` substring inside the template symbol does not
; trip the CHECK-NOT.
; CHECK-NOT: = fcmp
; CHECK-NOT: cq_theta_f32

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare float @cq_theta_f32(float, double)
declare i1 @cq_measure_i1(i1)

define i1 @example() {
entry:
  %a = call float @cq_theta_f32(float 2.0, double 5.000000e-01)
  ; Tainted handle `one` (ordered-not-equal) a right-hand float literal → `one` `_hl`.
  %c = fcmp one float %a, 1.0
  %m = call i1 @cq_measure_i1(i1 %c)
  ret i1 %m
}
