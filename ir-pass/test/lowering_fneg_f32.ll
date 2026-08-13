; lowering_fneg_f32.ll — Unary `fneg` for the f32 ABI. A tainted float
; handle flows through `fneg float` and lowers to the unary template
; `cq_template_fneg_f32(handle)` → handle. `fneg` is the only in-scope
; unary data op (PRD §1); the template is `(i32)->i32` (the handle's SSA
; type stays i32, the ABI width selects the symbol).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
;
; CHECK:     call i32 @cqrt_alloc_f32(float 2.500000e+00)
; CHECK:     call i32 @cq_template_fneg_f32(i32 %{{[a-zA-Z0-9_.]+}})
;
; CHECK-NOT: cq_theta_f32
; CHECK-NOT: fneg float

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare float @cq_theta_f32(float, double)

define void @example() {
entry:
  %a = call float @cq_theta_f32(float 2.500000e+00, double 5.000000e-01)
  %c = fneg float %a
  ret void
}
