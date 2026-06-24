; lowering_fcmp_ult_hl_f32.ll — 8rvn (Phase 7.1 iw81.4 §4.4): `fcmp ult`
; (unordered-or-less-than) is now in scope. A tainted data-position `ult` compare
; with a right-hand f32 literal lowers to `cq_template_fcmp_ult_f32_hl(i32,
; float)`. Handle on the LEFT → `_hl`, predicate unchanged (no flip).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; CHECK:     call i32 @cqrt_alloc_f32(float 2.000000e+00)
; CHECK:     call i32 @cq_template_fcmp_ult_f32_hl(i32 %{{[a-zA-Z0-9_.]+}}, float 1.000000e+00)
; CHECK:     call i1 @cqrt_measure_i1(i32 %{{[a-zA-Z0-9_.]+}})
;
; CHECK-NOT: = fcmp
; CHECK-NOT: cq_template_icmp_ult

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare float @cq_theta_f32(float, double)
declare i1 @cq_measure_i1(i1)

define i1 @example() {
entry:
  %a = call float @cq_theta_f32(float 2.0, double 5.000000e-01)
  %c = fcmp ult float %a, 1.0
  %m = call i1 @cq_measure_i1(i1 %c)
  ret i1 %m
}
