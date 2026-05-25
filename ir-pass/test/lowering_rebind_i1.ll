; lowering_rebind_i1.ll — Width-parametric mid-struct rebind (M15) for
; the i1 ABI. Pins that `qbool_mid_t` is recognized through
; `WidthDispatch::midStructToSuffix` (rather than the pre-M15 hard-coded
; `qint_mid_t`-only match) and that the per-init alloc target now
; switches to `cqrt_alloc_i1` instead of the legacy i32-pinned shim.
;
; The handle is still i32 across every ABI width per PRD §"Width
; unification"; only the alloc's argument type widens. This fixture
; isolates the rebind step: no `add`, no measure, so the M16/M17 paths
; (still i32-pinned pre-M17) don't fire. The dangling init has no users
; → step 7 (eraseDeadInits) reclaims it, and the cleanup loop drops the
; now-useless `cq_init_i1` declaration too.
;
; Spec: phases/phase2/PLAN.md §4.15.

; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -

; CHECK:     call i32 @cqrt_alloc_i1(i1 true)

; CHECK-NOT: cq_init_i1
; CHECK-NOT: cqrt_alloc_i32
; CHECK-NOT: extractvalue

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

%qbool_mid_t = type { i1 }

declare %qbool_mid_t @cq_init_i1(i1)

define void @example() {
entry:
  %a = call %qbool_mid_t @cq_init_i1(i1 true)
  ret void
}
