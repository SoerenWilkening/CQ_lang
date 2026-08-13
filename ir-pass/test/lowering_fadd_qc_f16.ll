; lowering_fadd_qc_f16.ll — Phase 7.1 Increment D: per-width Q+C (handle+literal)
; fadd for the f16 ABI. A tainted `half` handle plus a `half` literal lowers to
; `cq_template_fadd_f16_hl(i32 handle, half b_classical)` — the classical operand
; rides at its real `half` width (the handle is always i32). Complements
; lowering_fadd_qq_f16.ll (Q+Q): together they pin both f16 binary shapes.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
;
; CHECK:     call i32 @cqrt_alloc_f16(half %s)
; CHECK:     call i32 @cq_template_fadd_f16_hl(i32 %{{[a-zA-Z0-9_.]+}}, half 0xH3E00)
; CHECK:     call half @cqrt_measure_f16(i32 %{{[a-zA-Z0-9_.]+}})
;
; CHECK-NOT: call i32 @cq_template_fadd_f16(i32 %{{.*}}, i32
; CHECK-NOT: = fadd half
; CHECK-NOT: cq_theta_f16

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare half @cq_theta_f16(half, double)
declare half @cq_measure_f16(half)

define half @example(half %s) {
entry:
  %a = call half @cq_theta_f16(half %s, double 5.000000e-01)
  %r = fadd half %a, 0xH3E00
  %m = call half @cq_measure_f16(half %r)
  ret half %m
}
