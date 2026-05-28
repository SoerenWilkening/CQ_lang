; lowering_rebind_i64.ll — Width-parametric mid-struct rebind (M15) for
; the i64 ABI. Pins that `qlonglong_mid_t` is recognized through
; `WidthDispatch::midStructToSuffix` and that the per-init alloc target
; switches to `cqrt_alloc_i64` instead of the legacy i32-pinned shim.
;
; Four frontend suffixes map to the i64 ABI on LP64: `sl`, `ul` (via
; `DataLayout` pointer-width resolution), `sll`, `ull`. We pick `sll`
; (qlonglong_mid_t) — it's target-independent (resolves to i64 even on
; ILP32/LLP64 targets), so the fixture is portable.
;
; The handle is still i32 across every ABI width per PRD §"Width
; unification"; only the alloc's argument type widens to i64. This
; fixture isolates the rebind step: no `add`, no measure, so the
; M16/M17 paths (still i32-pinned pre-M17) don't fire.

; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -

; CHECK:     call i32 @cqrt_alloc_i64(i64 1234567890)

; CHECK-NOT: cq_init_sll
; CHECK-NOT: cqrt_alloc_i32
; CHECK-NOT: extractvalue

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

%qlonglong_mid_t = type { i64 }

declare %qlonglong_mid_t @cq_init_sll(i64)

define void @example() {
entry:
  %a = call %qlonglong_mid_t @cq_init_sll(i64 1234567890)
  ret void
}
