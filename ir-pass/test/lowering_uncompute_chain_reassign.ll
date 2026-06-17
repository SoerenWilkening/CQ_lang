; lowering_uncompute_chain_reassign.ll — Phase 5 headline (PRD §4 bullet 2
; / IMPLEMENTATION §4.2). A REASSIGNED single register: `q = cq_theta; q = q + 1;
; q = q * 2`. Rotation lowering mints the alloc + `cqrt_ry`; the two arithmetic
; reassignments lower to `cq_template_add_i32_hl` then `cq_template_mul_i32_hl`,
; each RAUW-producing a FRESH i32 result handle (q's SSA lineage h0 → h1 → h2).
;
; `ChainWalk::recoverForwardChain` + `isTerminalHandle` collapse that whole
; def-use lineage to ONE terminal (the mul result) by threading the producer's
; tainted operand back to the `cqrt_alloc` mint — NOT a BirthOrder walk (BirthOrder
; is only a cross-block tie-breaker). The forward chain [ry, add, mul] is recovered
; in program order and Phase 5 reverses it ONCE at the SSA last-use point via the
; VOID in-place `_unc` forms (WI-3, PRD §2.3): each `cq_template_<op>_<W>_hl_unc`
; takes `(out, src, lit)` — DD-3 slots: the forward call's OWN result handle is the
; rail to zero (`out`), the live forward source operand is read-and-preserved — so
; the reversed `mul_unc(h2, h1, 2)` reads the still-live `h1` and the `add_unc(h1,
; h0, 1)` reads the still-live `h0` (alloc root). The rotation re-emits in place
; with a NEGATED angle (no `_inv`/`_unc` rotation symbol exists). NOTHING is minted
; (the void uncompute zeroes the rail in place — never the fresh-minting `_inv`
; OPERATION, which would free a dirty rail = a hidden measurement, Rule 6/8). The
; `cqrt_free` targets the recovered ROOT (`h0`), now |0> after the un-rotation.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; Forward chain (theta → alloc + ry, then the two reassignments):
; CHECK:     call void @cqrt_ry_i32(i32 %[[H0:[a-zA-Z0-9_.]+]], double 2.500000e-01)
; CHECK:     %[[H1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[H0]], i32 1)
; CHECK:     %[[H2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[H1]], i32 2)
;
; Reversed whole-chain adjoint (LIFO) via the void in-place `_unc` forms:
; mul_unc(out=h2, src=h1) BEFORE add_unc(out=h1, src=h0) BEFORE ry(-θ), each
; reading its STILL-LIVE forward source; then free the |0> root h0. No fresh mint.
; CHECK:     call void @cq_template_mul_i32_hl_unc(i32 %[[H2]], i32 %[[H1]], i32 2)
; CHECK:     call void @cq_template_add_i32_hl_unc(i32 %[[H1]], i32 %[[H0]], i32 1)
; CHECK:     call void @cqrt_ry_i32(i32 %[[H0]], double -2.500000e-01)
; CHECK:     call void @cqrt_free(i32 %[[H0]])
;
; CHECK-NOT: cq_template_mul_i32_hl_inv
; CHECK-NOT: cq_template_add_i32_hl_inv
; CHECK-NOT: cq_theta_si32
; CHECK-NOT: add i32
; CHECK-NOT: mul i32
;
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)

define void @slice(i32 %x) {
entry:
  %h = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  %add = add i32 %h, 1
  %mul = mul i32 %add, 2
  ret void
}
