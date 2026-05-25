; lowering_measure_i1.ll — Width-parametric measure lowering (M17) for
; the i1 ABI. Pins that `cq_measure_i1` lowers to `cqrt_measure_i1`
; (returning i1) instead of the legacy i32-pinned shim.
;
; Only one frontend suffix maps to the i1 ABI: `i1` (qbool_mid_t). The
; handle stays i32 across every ABI width per PRD §"Width unification";
; only the return-value type widens. Init flows directly into measure
; (operand pattern (a) — struct→handle via rebind).
;
; Spec: phases/phase2/PLAN.md §4.17.

; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -

; CHECK:     call i32 @cqrt_alloc_i1(i1 true)
; CHECK:     call i1 @cqrt_measure_i1(i32

; CHECK-NOT: cq_init_i1
; CHECK-NOT: cq_measure_i1
; CHECK-NOT: cqrt_measure_i32

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

%qbool_mid_t = type { i1 }

declare %qbool_mid_t @cq_init_i1(i1)
declare i1           @cq_measure_i1(%qbool_mid_t)

define i1 @example() {
entry:
  %a_struct = call %qbool_mid_t @cq_init_i1(i1 true)
  %m        = call i1 @cq_measure_i1(%qbool_mid_t %a_struct)
  ret i1 %m
}
