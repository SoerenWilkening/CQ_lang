; lowering_fpext_f16_to_f32.ll — Phase 7.1 Increment D: fp-width WIDENING cast
; from half to float. A tainted `half` handle flows through `fpext half to
; float` and lowers to the unary cast template
; `cq_template_fpext_f16_to_f32(handle)` → handle. The width pair selects the
; symbol; the handle is i32 on both sides. This pins the cast DIRECTION:
; castInScope admits fpext only when fpBits(from) < fpBits(to) (16 < 32), so the
; f16->f32 widen is in scope; the reverse narrow is an `fptrunc`, not `fpext`
; (a literal `fpext float to half` is malformed IR the verifier rejects).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; CHECK:     call i32 @cqrt_alloc_f16(half 0xH3C00)
; CHECK:     call i32 @cq_template_fpext_f16_to_f32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call float @cqrt_measure_f32(i32 %{{[a-zA-Z0-9_.]+}})
;
; CHECK-NOT: = fpext
; CHECK-NOT: cq_theta_f16

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare half @cq_theta_f16(half, double)
declare float @cq_measure_f32(float)

define float @example() {
entry:
  %a = call half @cq_theta_f16(half 0xH3C00, double 5.000000e-01)
  %c = fpext half %a to float
  %m = call float @cq_measure_f32(float %c)
  ret float %m
}
