; lowering_uncompute_dead_sibling_no_measure.ll — ACCEPT: the don't-over-decline
; twin of lowering_uncompute_dead_sibling_premeasure.ll (test_C_libtooling-3h8).
;
; Same DEAD tainted template terminal (`%q = cq_theta(...)`; `%dead = q + 7`,
; never read) — but NO measurement reads the register on any lineage handle.
; The whole-chain adjoint + `cqrt_free` is then sound and Phase 5 emits it: the
; lineage-measure decline fires ONLY when a non-terminal lineage handle is
; measured, never for an ordinary dead chain.
;
; The adjoint is the VOID in-place `_unc` form (WI-3, PRD §2.3): `add_i32_hl_unc(
; out=%dead, src=%q, 7)` zeroes the dead rail by reading the still-live alloc root
; `%q` (DD-3 slots: out, then forward operands) — NOT the fresh-minting `_inv`
; OPERATION (which frees a dirty rail = a hidden measurement, Rule 6/8). The
; `cqrt_free` then targets the |0> root `%q`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; Forward chain (theta → alloc + ry, then the dead reassignment):
; CHECK:     call void @cqrt_ry_i32(i32 %[[H:[a-zA-Z0-9_.]+]], double 2.500000e-01)
; CHECK:     %[[D:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[H]], i32 7)
; Reversed adjoint (void in-place `_unc`, reading the live root) + free of the root:
; CHECK:     call void @cq_template_add_i32_hl_unc(i32 %[[D]], i32 %[[H]], i32 7)
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double -2.500000e-01)
; CHECK:     call void @cqrt_free(i32 %[[H]])
;
; CHECK-NOT: cq_template_add_i32_hl_inv
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
