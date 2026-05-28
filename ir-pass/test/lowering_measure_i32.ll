; lowering_measure_i32.ll — Width-parametric measure lowering (M17) for
; the i32 ABI. Pins that `cq_measure_si32` is routed through the M17
; suffix → ABI-width resolution path (rather than the pre-M17 hard-coded
; i32 shim). The symbol output is identical to Phase 1 because i32 was
; already the legacy width, but the resolution path is new.
;
; Two frontend suffixes share the i32 ABI (`si32`, `ui32`); only one
; needs an L3 fixture. We pick `si32` (qint_mid_t) — it's the Phase 1
; lineage carrier. Init flows directly into measure (operand pattern (a)
; — struct→handle via rebind). The end-to-end Phase 1 pattern with add
; is already covered by `lowering_basic.ll` and `measure_only.ll`; this
; fixture keeps the M17-shape uniform with the other six.

; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -

; CHECK:     call i32 @cqrt_alloc_i32(i32 99)
; CHECK:     call i32 @cqrt_measure_i32(i32

; CHECK-NOT: cq_init_si32
; CHECK-NOT: cq_measure_si32

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

%qint_mid_t = type { i32 }

declare %qint_mid_t @cq_init_si32(i32)
declare i32         @cq_measure_si32(%qint_mid_t)

define i32 @example() {
entry:
  %a_struct = call %qint_mid_t @cq_init_si32(i32 99)
  %m        = call i32 @cq_measure_si32(%qint_mid_t %a_struct)
  ret i32 %m
}
