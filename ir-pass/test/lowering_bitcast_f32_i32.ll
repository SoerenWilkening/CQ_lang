; lowering_bitcast_f32_i32.ll — p119.7: the float-family GET_FLOAT_WORD idiom.
; A tainted f32 theta handle is reinterpreted to i32 (`bitcast float to i32`),
; pinning that the reinterpret template family covers every shipped fp<->int
; width, not just f64<->i64. Lowers to `cq_template_bitcast_f32_to_i32`. (f16<->i16
; ships the same way; f80<->i80 is EXCLUDED — no i80 width — see
; lowering_reject_bitcast_f80_i80.ll.)
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; CHECK:     call i32 @cqrt_alloc_f32(float 5.000000e-01)
; CHECK:     call i32 @cq_template_bitcast_f32_to_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: = bitcast

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare float @cq_theta_f32(float, double)
declare i32 @cq_measure_si32(i32)

define i32 @example() {
entry:
  %q = call float @cq_theta_f32(float 5.000000e-01, double 5.000000e-01)
  %i = bitcast float %q to i32          ; GET_FLOAT_WORD: fp -> int reinterpret
  %m = call i32 @cq_measure_si32(i32 %i)
  ret i32 %m
}
