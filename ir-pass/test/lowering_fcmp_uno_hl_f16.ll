; lowering_fcmp_uno_hl_f16.ll — 8rvn (Phase 7.1 iw81.4 §4.4) × Increment D
; (f16): `fcmp uno` (unordered — at least one operand is NaN, the
; `__builtin_isunordered` predicate) is now in scope. A tainted data-position
; `uno` compare with a right-hand `half` literal lowers to
; `cq_template_fcmp_uno_f16_hl(i32, half)`. Proves the new order-test predicate
; rides the new f16 width (HL: classical operand keeps its real `half` type).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
;
; CHECK:     call i32 @cqrt_alloc_f16(half 0xH4000)
; CHECK:     call i32 @cq_template_fcmp_uno_f16_hl(i32 %{{[a-zA-Z0-9_.]+}}, half 0xH3C00)
; CHECK:     call i1 @cqrt_measure_i1(i32 %{{[a-zA-Z0-9_.]+}})
;
; CHECK-NOT: = fcmp
; CHECK-NOT: cq_template_icmp

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare half @cq_theta_f16(half, double)
declare i1 @cq_measure_i1(i1)

define i1 @example() {
entry:
  %a = call half @cq_theta_f16(half 0xH4000, double 5.000000e-01)
  ; 0xH3C00 = 1.0 in f16.
  %c = fcmp uno half %a, 0xH3C00
  %m = call i1 @cq_measure_i1(i1 %c)
  ret i1 %m
}
