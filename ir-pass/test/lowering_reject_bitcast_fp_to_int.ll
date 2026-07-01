; lowering_reject_bitcast_fp_to_int.ll — bd iw81.1 DECLINE: the OTHER fp<->int
; direction, an fp→int `bitcast` REINTERPRET (`bitcast float to i32`, the C
; `__builtin_bit_cast(int, someFloat)`), loud-declines too. Symmetric to
; lowering_reject_bitcast_int_to_fp.ll: `castInScope` admits `bitcast` only for the
; same-width int<->int pair, so a float source (`intBits` 0) fails `fi && ti` and
; the reinterpret has no template (`diagnoseNoTemplate`). Reinterpreting a float's
; bits as an integer is the inverse crossing of the f64-as-angle fence — never a
; benign identity — so both directions of the reinterpret subset stay declined.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare float @cq_theta_f32(float, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(float %u0) {
entry:
  %q = call float @cq_theta_f32(float %u0, double 5.000000e-01)  ; tainted f32
  %i = bitcast float %q to i32                                   ; fp reinterpret, FENCED
  %m = call i32 @cq_measure_si32(i32 %i)
  ret i32 %m
}

; CHECK: error{{.*}}no template for opcode 'bitcast i32' in tainted context
; CHECK-NOT: cq_template_bitcast
