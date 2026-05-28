; lowering_rebind_i8.ll — Width-parametric mid-struct rebind (M15) for
; the i8 ABI. Pins that `qschar_mid_t` is recognized through
; `WidthDispatch::midStructToSuffix` (rather than the pre-M15 hard-coded
; `qint_mid_t`-only match) and that the per-init alloc target now
; switches to `cqrt_alloc_i8` instead of the legacy i32-pinned shim.
;
; Three frontend suffixes share the i8 ABI (`c`, `si8`, `ui8`); only
; one needs an L3 fixture because signedness is invisible to the IR
; pass at this level. We pick `si8` (qschar_mid_t).
;
; The handle is still i32 across every ABI width per PRD §"Width
; unification"; only the alloc's argument type widens. This fixture
; isolates the rebind step: no `add`, no measure, so the M16/M17 paths
; (still i32-pinned pre-M17) don't fire. The dangling init has no users
; → step 7 (eraseDeadInits) reclaims it.

; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -

; CHECK:     call i32 @cqrt_alloc_i8(i8 7)

; CHECK-NOT: cq_init_si8
; CHECK-NOT: cqrt_alloc_i32
; CHECK-NOT: extractvalue

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

%qschar_mid_t = type { i8 }

declare %qschar_mid_t @cq_init_si8(i8)

define void @example() {
entry:
  %a = call %qschar_mid_t @cq_init_si8(i8 7)
  ret void
}
