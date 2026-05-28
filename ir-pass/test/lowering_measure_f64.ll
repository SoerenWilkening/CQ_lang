; lowering_measure_f64.ll — Width-parametric measure lowering (M17) for
; the f64 ABI. Pins that `cq_measure_f64` lowers to `cqrt_measure_f64`
; (returning double) instead of the legacy i32-pinned shim.
;
; Only one frontend suffix maps to the f64 ABI: `f64` (qdouble_mid_t).
; The handle is still i32 across every ABI width per PRD §"Width
; unification"; only the measure's return type widens to double. Init
; flows directly into measure (operand pattern (a) — struct→handle via
; rebind).

; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -

; CHECK:     call i32 @cqrt_alloc_f64(double 2.718280e+00)
; CHECK:     call double @cqrt_measure_f64(i32

; CHECK-NOT: cq_init_f64
; CHECK-NOT: cq_measure_f64
; CHECK-NOT: cqrt_measure_i32

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

%qdouble_mid_t = type { double }

declare %qdouble_mid_t @cq_init_f64(double)
declare double         @cq_measure_f64(%qdouble_mid_t)

define double @example() {
entry:
  %a_struct = call %qdouble_mid_t @cq_init_f64(double 2.718280e+00)
  %m        = call double @cq_measure_f64(%qdouble_mid_t %a_struct)
  ret double %m
}
