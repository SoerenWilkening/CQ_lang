; lowering_fneg_f16.ll — Phase 7.1 Increment D: unary `fneg` for the f16 ABI.
; A tainted `half` handle flows through `fneg half` and lowers to the unary
; template `cq_template_fneg_f16(handle)` → handle. `fneg` is the only in-scope
; unary data op; the template is `(i32)->i32` (the handle's SSA type stays i32,
; the ABI width selects the symbol).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; CHECK:     call i32 @cqrt_alloc_f16(half 0xH4000)
; CHECK:     call i32 @cq_template_fneg_f16(i32 %{{[a-zA-Z0-9_.]+}})
;
; CHECK-NOT: cq_theta_f16
; CHECK-NOT: fneg half

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare half @cq_theta_f16(half, double)

define void @example() {
entry:
  %a = call half @cq_theta_f16(half 0xH4000, double 5.000000e-01)
  %c = fneg half %a
  ret void
}
