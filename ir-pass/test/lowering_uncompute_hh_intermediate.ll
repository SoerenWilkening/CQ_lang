; lowering_uncompute_hh_intermediate.ll — Phase 5 Step 3 (PRD §4 bullet 4 /
; IMPLEMENTATION §4.3, decision 2.5). An HH-style intermediate `t = q1 * q2`
; whose product handle is the chain TERMINAL and is consumed only by
; `cq_measure` (lowered to `cqrt_measure_<W>`). Measurement is a terminator: a
; measured handle gets NO adjoint and NO `cqrt_free`, and the measure call is
; EXCLUDED from the last-use post-dominator set (a sink, not an ordinary use).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; The forward product + its measurement still lower:
; CHECK:     call i32 @cq_template_mul_i32(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call i32 @cqrt_measure_i32(i32 %{{[a-zA-Z0-9_.]+}})
;
; …but the measured terminal gets neither an adjoint twin nor a free:
; CHECK-NOT: cq_template_mul_i32_inv
; CHECK-NOT: cqrt_free
;
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define void @slice(i32 %x, i32 %y) {
entry:
  %q1 = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  %q2 = call i32 @cq_theta_si32(i32 %y, double 3.500000e-01)
  %t = mul i32 %q1, %q2
  %m = call i32 @cq_measure_si32(i32 %t)
  ret void
}
