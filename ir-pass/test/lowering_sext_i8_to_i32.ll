; lowering_sext_i8_to_i32.ll — Widen cast: `cq_template_sext_i8_to_i32`. Pins
; the widen cast pair AND the per-cast-pair capture-before-RAUW (risk R1),
; complementary to the compare-feeds-zext bridge fixture.
;
; Shaping note (forced by the pass pipeline): RotationLowering runs BEFORE
; OpcodeLowering and RAUWs every theta result to an i32 handle. So a cast that
; reads a theta result DIRECTLY would, by the time OpcodeLowering captures
; widths, see an i32 source — the narrow source width would already be gone.
; The only tainted values that still carry a non-i32 width when OpcodeLowering
; collects are (a) a compare result (i1; the bridge fixture's case) and (b)
; the result of ANOTHER cast in the same function, because OpcodeLowering's
; phase-1 collection reads each cast's ORIGINAL result type BEFORE phase-2
; lowers (and RAUWs) it. This fixture uses (b): an i32 handle is narrowed to
; i8, and that i8 value is the source of the widen.
;
;   theta(i32) ──rotation──► i32 handle %h
;   %n = trunc i32 %h to i8     ; in-scope narrow; result type i8
;   %w = sext  i8  %n to i32    ; the WIDEN under test
;
; CAPTURE-BEFORE-RAUW (R1): at phase-1 collection both casts are well-typed,
; so the driver captures (i32→i8) for the trunc and (i8→i32) for the sext —
; reading %n as i8. In phase-2 the trunc lowers first and RAUWs %n to its i32
; handle, so by the time `rewriteCast` runs on the sext its operand is i32 and
; a live `getSrcTy()` read would yield i32 (→ the garbage `sext i32_to_i32`,
; which is not even in scope). Because the symbol uses the CAPTURED i8 source,
; cast lowering emits `cq_template_sext_i8_to_i32` correctly. The CHECK-NOT
; locks the garbage symbol out.
;
; Both cast results are i32 handles flowing to a measure (`cq_measure_si32` →
; `cqrt_measure_i32`); the second RUN line GUARDS the cross-type RAUWs
; (risk R2).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; CHECK:     call i32 @cqrt_alloc_i32(i32 7)
; CHECK:     call i32 @cq_template_trunc_i32_to_i8(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call i32 @cq_template_sext_i8_to_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call i32 @cqrt_measure_i32(i32 %{{[a-zA-Z0-9_.]+}})
;
; The garbage symbol from a rewrite-time width read must NOT appear, and the
; bare casts must be gone (lowered).
; CHECK-NOT: cq_template_sext_i32_to_i32
; CHECK-NOT: = sext
; CHECK-NOT: = trunc
; CHECK-NOT: cq_theta_si32

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example() {
entry:
  %a = call i32 @cq_theta_si32(i32 7, double 5.000000e-01)
  ; Manufacture a width-preserved i8 source (its i8 result type is read at
  ; phase-1 before the trunc itself is lowered).
  %n = trunc i32 %a to i8
  ; The widen under test: tainted i8 source → cq_template_sext_i8_to_i32.
  %w = sext i8 %n to i32
  ; Measure the i32 cast handle (suffix si32 → ABI i32 → cqrt_measure_i32).
  %m = call i32 @cq_measure_si32(i32 %w)
  ret i32 %m
}
