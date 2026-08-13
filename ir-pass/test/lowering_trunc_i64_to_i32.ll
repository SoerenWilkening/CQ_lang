; lowering_trunc_i64_to_i32.ll — Narrow cast: `cq_template_trunc_i64_to_i32`.
; Pins the narrow cast pair AND the per-cast-pair capture-before-RAUW (R1).
;
; Shaping note (forced by the pass pipeline; see lowering_sext_i8_to_i32.ll for
; the full rationale): RotationLowering runs BEFORE OpcodeLowering and RAUWs
; every theta result to an i32 handle, so a cast reading a theta result
; directly would lose its non-i32 source width before OpcodeLowering captures
; it. To get a width-preserved i64 source we widen the i32 handle to i64 first;
; OpcodeLowering's phase-1 collection reads that `sext`'s ORIGINAL i64 result
; type before phase-2 lowers it.
;
;   theta(i32) ──rotation──► i32 handle %h
;   %w = sext  i32 %h to i64    ; in-scope widen; result type i64
;   %t = trunc i64 %w to i32    ; the NARROW under test
;
; CAPTURE-BEFORE-RAUW (R1): at phase-1 both casts are well-typed, so the driver
; captures (i32→i64) for the sext and (i64→i32) for the trunc — reading %w as
; i64. In phase-2 the sext lowers first and RAUWs %w to its i32 handle, so by
; the time `rewriteCast` runs on the trunc its operand is i32 and a live
; `getSrcTy()` read would yield i32 (→ the garbage `trunc i32_to_i32`, which
; is not even in scope — trunc requires a strictly wider source). Because the
; symbol uses the CAPTURED i64 source, cast lowering emits
; `cq_template_trunc_i64_to_i32` correctly. The CHECK-NOT locks the garbage out.
;
; Both cast results are i32 handles flowing to a measure (`cq_measure_si32` →
; `cqrt_measure_i32`); the second RUN line GUARDS the cross-type RAUWs (R2).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; CHECK:     call i32 @cqrt_alloc_i32(i32 9)
; CHECK:     call i32 @cq_template_sext_i32_to_i64(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call i32 @cq_template_trunc_i64_to_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call i32 @cqrt_measure_i32(i32 %{{[a-zA-Z0-9_.]+}})
;
; The garbage symbol from a rewrite-time width read must NOT appear, and the
; bare casts must be gone (lowered).
; CHECK-NOT: cq_template_trunc_i32_to_i32
; CHECK-NOT: = trunc
; CHECK-NOT: = sext
; CHECK-NOT: cq_theta_si32

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example() {
entry:
  %a = call i32 @cq_theta_si32(i32 9, double 5.000000e-01)
  ; Manufacture a width-preserved i64 source (its i64 result type is read at
  ; phase-1 before the sext itself is lowered).
  %w = sext i32 %a to i64
  ; The narrow under test: tainted i64 source → cq_template_trunc_i64_to_i32.
  %t = trunc i64 %w to i32
  ; Measure the i32 cast handle (suffix si32 → ABI i32 → cqrt_measure_i32).
  %m = call i32 @cq_measure_si32(i32 %t)
  ret i32 %m
}
