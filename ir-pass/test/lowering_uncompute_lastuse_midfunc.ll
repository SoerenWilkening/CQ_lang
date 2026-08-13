; lowering_uncompute_lastuse_midfunc.ll — Phase 5 Step 1 headline (PRD §4
; bullet 1 / IMPLEMENTATION §4.1). A mid-function, non-`main` last use of a
; rotation-only single-register terminal: `cq_theta` prepares a handle that is
; never measured and never returned (its lifetime ends inside the function), so
; Phase 5 emits the whole-chain adjoint at the SSA last-use point followed by
; `cqrt_free`.
;
; Body pinned to a SINGLE rotation (no arithmetic, no measure on the handle) so
; commit 1's rotation-negate-only EmitInverse fully covers it: the forward
; `cqrt_ry_i32(h, θ)` lowered from `cq_theta` is uncomputed by re-emitting the
; SAME symbol with the NEGATED angle (no `_inv` rotation symbol exists), then the
; handle is freed. Template `_inv` assertions are deferred to Step 2.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; The forward rotation (theta → alloc + ry):
; CHECK:     call void @cqrt_ry_i32(i32 %[[H:[a-zA-Z0-9_.]+]], double 2.500000e-01)
; The reversed adjoint: SAME symbol, SAME handle, NEGATED angle.
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double -2.500000e-01)
; Then free the now-zeroed handle.
; CHECK:     call void @cqrt_free(i32 %[[H]])
;
; CHECK-NOT: cq_theta_si32
;
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)

define void @slice(i32 %x) {
entry:
  %h = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  ret void
}
