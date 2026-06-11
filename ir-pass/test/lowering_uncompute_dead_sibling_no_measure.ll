; lowering_uncompute_dead_sibling_no_measure.ll — ACCEPT: the don't-over-decline
; twin of lowering_uncompute_dead_sibling_premeasure.ll (test_C_libtooling-3h8).
;
; Same DEAD tainted template terminal (`%q = cq_theta(...)`; `%dead = q + 7`,
; never read) — but NO measurement reads the register on any lineage handle.
; The whole-chain adjoint + `cqrt_free` is then sound and Phase 5 emits it: the
; lineage-measure decline fires ONLY when a non-terminal lineage handle is
; measured, never for an ordinary dead chain.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; Forward chain (theta → alloc + ry, then the dead reassignment):
; CHECK:     call void @cqrt_ry_i32(i32 %[[H:[a-zA-Z0-9_.]+]], double 2.500000e-01)
; CHECK:     call i32 @cq_template_add_i32_hl(i32 %[[H]], i32 7)
; Reversed adjoint + free of the now-zeroed handle:
; CHECK:     call i32 @cq_template_add_i32_hl_inv(i32 %{{[a-zA-Z0-9_.]+}}, i32 7)
; CHECK:     call void @cqrt_ry_i32(i32 %{{[a-zA-Z0-9_.]+}}, double -2.500000e-01)
; CHECK:     call void @cqrt_free(i32 %{{[a-zA-Z0-9_.]+}})
;
; CHECK-NOT: cq_theta_si32
;
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)

define void @slice(i32 %x) {
entry:
  %q    = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  %dead = add i32 %q, 7                          ; DEAD tainted template terminal, no measure
  ret void
}
