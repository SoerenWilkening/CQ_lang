; lowering_sitofp_i32_to_f64.ll — Domain-cross cast (int → fp). A tainted i32
; handle flows through `sitofp i32 %h to f64` and lowers to the unary cast
; template `cq_template_sitofp_i32_to_f64(handle)` → handle. The template is
; `(i32)→i32`: the (i32→f64) width pair selects the symbol, but the HANDLE is
; i32 on both sides regardless of the domain crossing.
;
; This is the NON-i32-RESULT case (the payoff for the cross-type RAUW
; mechanism): the original `sitofp` yields an f64 SSA value, and lowering
; RAUWs that f64 value with the i32 handle — a cross-type RAUW laundered by
; erasure (IMPLEMENTATION §1.2 / risk R2), identical to CompareLowering's
; i1-flag RAUW. The f64 result flows to a measure (`cq_measure_f64` →
; `cqrt_measure_f64`): the measure's f64 operand is RAUW'd to the i32 handle,
; `cqrt_measure_f64(i32 handle)` consumes it, and erasing both the malformed
; sitofp and the original measure leaves the IR well-typed. The second RUN
; line GUARDS that this cross-type-on-fp RAUW is verify-clean.
;
; sitofp (signed int → fp) is in scope for non-i1 source widths
; (`castInScope`: sitofp excludes i1 — no signed bool); i32→f64 is a
; representative crossing.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
;
; CHECK:     call i32 @cqrt_alloc_i32(i32 5)
; CHECK:     call i32 @cq_template_sitofp_i32_to_f64(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call double @cqrt_measure_f64(i32 %{{[a-zA-Z0-9_.]+}})
;
; The bare `sitofp` must be gone (lowered).
; CHECK-NOT: = sitofp
; CHECK-NOT: cq_theta_si32

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare double @cq_measure_f64(double)

define double @example() {
entry:
  %a = call i32 @cq_theta_si32(i32 5, double 5.000000e-01)
  ; Tainted i32 handle crossed to f64 → cq_template_sitofp_i32_to_f64.
  ; The f64 result is RAUW'd to the i32 handle (cross-type, laundered).
  %c = sitofp i32 %a to double
  %m = call double @cq_measure_f64(double %c)
  ret double %m
}
