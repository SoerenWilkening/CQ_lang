; lowering_measure_i64.ll — Width-parametric measure lowering (M17) for
; the i64 ABI. Pins that `cq_measure_sll` lowers to `cqrt_measure_i64`
; (returning i64) instead of the legacy i32-pinned shim.
;
; Four frontend suffixes map to the i64 ABI on LP64: `sl`, `ul` (via
; `DataLayout` pointer-width resolution), `sll`, `ull`. We pick `sll`
; (qlonglong_mid_t) — it's target-independent (resolves to i64 even on
; ILP32/LLP64 targets), so the fixture is portable.
;
; The handle is still i32 across every ABI width per PRD §"Width
; unification"; only the measure's return type widens to i64. Init flows
; directly into measure (operand pattern (a) — struct→handle via rebind).

; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -

; CHECK:     call i32 @cqrt_alloc_i64(i64 1234567890)
; CHECK:     call i64 @cqrt_measure_i64(i32

; CHECK-NOT: cq_init_sll
; CHECK-NOT: cq_measure_sll
; CHECK-NOT: cqrt_measure_i32

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

%qlonglong_mid_t = type { i64 }

declare %qlonglong_mid_t @cq_init_sll(i64)
declare i64              @cq_measure_sll(%qlonglong_mid_t)

define i64 @example() {
entry:
  %a_struct = call %qlonglong_mid_t @cq_init_sll(i64 1234567890)
  %m        = call i64 @cq_measure_sll(%qlonglong_mid_t %a_struct)
  ret i64 %m
}
