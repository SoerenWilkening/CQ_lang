; lowering_measure_i16.ll — Width-parametric measure lowering for
; the i16 ABI. Pins that `cq_measure_si16` lowers to `cqrt_measure_i16`
; (returning i16) instead of the legacy i32-pinned shim.
;
; Two frontend suffixes share the i16 ABI (`si16`, `ui16`); only one
; needs an L3 fixture because signedness is invisible to the runtime
; symbol. We pick `si16` (qshort_mid_t). Init flows directly into
; measure (operand pattern (a) — struct→handle via rebind).

; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -

; CHECK:     call i32 @cqrt_alloc_i16(i16 1234)
; CHECK:     call i16 @cqrt_measure_i16(i32

; CHECK-NOT: cq_init_si16
; CHECK-NOT: cq_measure_si16
; CHECK-NOT: cqrt_measure_i32

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

%qshort_mid_t = type { i16 }

declare %qshort_mid_t @cq_init_si16(i16)
declare i16           @cq_measure_si16(%qshort_mid_t)

define i16 @example() {
entry:
  %a_struct = call %qshort_mid_t @cq_init_si16(i16 1234)
  %m        = call i16 @cq_measure_si16(%qshort_mid_t %a_struct)
  ret i16 %m
}
