; lowering_reject_bitcast_int_to_fp.ll — bd iw81.1 DECLINE: an int→fp `bitcast`
; REINTERPRET (`bitcast i32 to float`, the C `__builtin_bit_cast(float, someInt)`)
; loud-declines. Same-width int<->int bitcast is a zero-gate identity, but the
; fp<->int reinterpret subset is DELIBERATELY EXCLUDED from `castInScope`: an fp
; width gives `intBits` 0, so `fi && ti` is false and the reinterpret has no
; template — it hits `diagnoseNoTemplate` (Prime Directive). Reinterpreting a
; quantum bit pattern as a float would cross the f64-as-angle fence (Rule 3): the
; produced float could reach a rotation arg-1 as an angle, the exact silent-
; miscompile family the exclusion protects. The carve-out doubles as this decline
; fixture for the f64 hazard.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare float @cq_measure_f32(float)

define float @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)  ; tainted i32
  %f = bitcast i32 %q to float                                ; fp reinterpret, FENCED
  %m = call float @cq_measure_f32(float %f)
  ret float %m
}

; CHECK: error{{.*}}no template for opcode 'bitcast float' in tainted context
; CHECK-NOT: cq_template_bitcast
