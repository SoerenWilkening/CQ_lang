; lowering_q_plus_c.ll — Mixed-operand Q+C dispatch, IN PLACE. A tainted add
; whose other operand is a ConstantInt lowers to the void in-place
; `cqrt_addc_i32(handle, literal)`; the lhs-constant spelling (`7 + q`) resolves
; to the SAME form, so the operand-position swap this file has always pinned is
; still pinned — the handle is found by TAINT, never by position (bd
; test_C_libtooling-6uqc, M-C Increment 2a; the out-of-place `_hl`/`_lh` twin at
; this and every other width is lowering_add_qc_i32.ll and its siblings).
;
; TWO THINGS THIS PINS THAT NO OTHER FIXTURE DOES:
;   * A CHAIN of reassignments (`q += 5; q += 7`) collapses onto ONE rail. The
;     second site's parent is the FIRST add — an instruction this same Phase-1
;     walk has already decided to convert — and it still converts, because
;     `rewriteInPlaceValueRail` RAUWs each result to the handle, so by Phase 2
;     both gates name the one register. Exactly one `cqrt_alloc_i32` in the
;     output; the measurement reads the handle itself.
;   * `add i32 7, %d` (literal on the LEFT) converts too. `_lh` is a lowering
;     artefact of the out-of-place family; an in-place add of a classical is
;     direction-free, and `inPlaceValueRailOperand` picks the operand by taint.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 3)
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK:     call void @cqrt_addc_i32(i32 %[[H]], i32 5)
; CHECK:     call void @cqrt_addc_i32(i32 %[[H]], i32 7)
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[H]])
;
; No second rail is minted, and no out-of-place add survives in either direction:
; CHECK-NOT: call i32 @cqrt_alloc_i32(
; CHECK-NOT: cq_template_add_
; CHECK-NOT: cq_theta_si32
; CHECK-NOT: cq_measure_si32
; CHECK-NOT: add i32

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example() {
entry:
  %a = call i32 @cq_theta_si32(i32 3, double 5.000000e-01)
  %d = add i32 %a, 5    ; rhs constant
  %e = add i32 7, %d    ; lhs constant; the handle is found by taint, not position
  %m = call i32 @cq_measure_si32(i32 %e)
  ret i32 %m
}
