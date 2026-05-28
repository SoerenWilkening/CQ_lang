; lowering_measure_i8.ll — Width-parametric measure lowering (M17) for
; the i8 ABI. Pins that `cq_measure_si8` lowers to `cqrt_measure_i8`
; (returning i8) instead of the legacy i32-pinned shim.
;
; Three frontend suffixes share the i8 ABI (`c`, `si8`, `ui8`); only one
; needs an L3 fixture because signedness is invisible to the runtime
; symbol (PRD §"Width unification"). We pick `si8` (qschar_mid_t).
;
; Init flows directly into measure (operand pattern (a) — struct→handle
; via rebind).

; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -

; CHECK:     call i32 @cqrt_alloc_i8(i8 42)
; CHECK:     call i8 @cqrt_measure_i8(i32

; CHECK-NOT: cq_init_si8
; CHECK-NOT: cq_measure_si8
; CHECK-NOT: cqrt_measure_i32

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

%qschar_mid_t = type { i8 }

declare %qschar_mid_t @cq_init_si8(i8)
declare i8            @cq_measure_si8(%qschar_mid_t)

define i8 @example() {
entry:
  %a_struct = call %qschar_mid_t @cq_init_si8(i8 42)
  %m        = call i8 @cq_measure_si8(%qschar_mid_t %a_struct)
  ret i8 %m
}
