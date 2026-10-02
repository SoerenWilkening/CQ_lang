; lowering_uncompute_dead_sibling_no_measure.ll — ACCEPT: the don't-over-decline
; twin of lowering_uncompute_dead_sibling_premeasure.ll (test_C_libtooling-3h8).
;
; Same DEAD tainted template terminal (`%q = cq_theta(...)`; `%dead = q + 7`,
; never read) — but NO measurement reads the register on any lineage handle.
; The whole-chain adjoint is then sound and Phase 5 emits it (the root is then
; kept, not freed — its runtime seed is not |0>, bd 5c5b): the lineage-measure
; decline fires ONLY when a non-terminal lineage handle is measured, never for an
; ordinary dead chain.
;
; The adjoint is the VOID in-place `_unc` form (WI-3, PRD §2.3): `add_i32_hl_unc(
; out=%dead, src=%q, 7)` zeroes the dead rail by reading the still-live alloc root
; `%q` (DD-3 slots: out, then forward operands) — NOT the fresh-minting `_inv`
; OPERATION (which frees a dirty rail = a hidden measurement, Rule 6/8). The root
; `%q` is then un-rotated back to its runtime seed |x> — NOT |0> — so it is kept,
; never freed (bd 5c5b, libcqops vmz9; this used to say "the |0> root" and the
; free it licensed was dirty).
;
; M-C NOTE (bd test_C_libtooling-6uqc, Increment 2a): the dead `q + 7` lowers IN
; PLACE, so the adjoint is the negated-immediate `cqrt_addc_i32(h, -7)` rather
; than a data `_unc`, and there is ONE rail instead of two. The accept boundary
; this file holds against lowering_uncompute_dead_sibling_premeasure.ll (no
; measurement on the lineage => reverse; free only what is born |0>) is unchanged.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOFREEROOT < %t.cqd0.ll
;
; Forward chain (theta → alloc + ry, then the dead reassignment):
; CHECK:     call void @cqrt_ry_i32(i32 %[[H:[a-zA-Z0-9_.]+]], double 2.500000e-01)
; CHECK:     call void @cqrt_addc_i32(i32 %[[H]], i32 7)
; Reversed adjoint (the in-place addc's negated immediate, then the un-rotation); the
; root is then kept, not freed (runtime seed |x>, bd 5c5b):
; CHECK:     call void @cqrt_addc_i32(i32 %[[H]], i32 -7)
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double -2.500000e-01)
; CHECK-NEXT: ret void
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

; bd 5c5b review r2: the root is never freed ANYWHERE after its birth — own prefix,
; one anchor (the alloc), so the window runs alloc -> EOF and also covers a free
; slipped in BEFORE the root's un-rotation; `tools/fixture_guard_liveness.py`
; checks the window by injection.
; NOFREEROOT:     %[[RT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %x)
; NOFREEROOT-NOT: call void @cqrt_free(i32 %[[RT]])
