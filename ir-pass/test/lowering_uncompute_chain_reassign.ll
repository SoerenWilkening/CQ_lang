; lowering_uncompute_chain_reassign.ll — Phase 5 Step 2 headline (PRD §4 bullet 2
; / IMPLEMENTATION §4.2). A REASSIGNED single register: `q = cq_theta; q = q + 1;
; q = q * 2`. Rotation lowering mints the alloc + `cqrt_ry`; the two arithmetic
; reassignments lower to `cq_template_add_i32_hl` then `cq_template_mul_i32_hl`,
; each RAUW-producing a FRESH i32 result handle (q's SSA lineage h0 → h1 → h2).
;
; `ChainWalk::recoverForwardChain` + `isTerminalHandle` collapse that whole
; def-use lineage to ONE terminal (the mul result) by threading the producer's
; tainted operand back to the `cqrt_alloc` mint — NOT a BirthOrder walk (BirthOrder
; is only a cross-block tie-breaker). The forward chain [ry, add, mul] is recovered
; in program order and Phase 5 reverses it ONCE at the SSA last-use point: the
; `_inv` template twins (each minting and threading a FRESH handle, R-template-inv-
; fresh-handle) in reverse, then the rotation re-emitted with a NEGATED angle (no
; `_inv` rotation symbol exists), then `cqrt_free` of the final threaded handle.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; Forward chain (theta → alloc + ry, then the two reassignments):
; CHECK:     call void @cqrt_ry_i32(i32 %[[H0:[a-zA-Z0-9_.]+]], double 2.500000e-01)
; CHECK:     call i32 @cq_template_add_i32_hl(i32 %[[H0]], i32 1)
; CHECK:     call i32 @cq_template_mul_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 2)
;
; Reversed whole-chain adjoint (LIFO): mul_inv BEFORE add_inv BEFORE ry(-θ),
; threading the fresh handle each step, then free the final handle.
; CHECK:     call i32 @cq_template_mul_i32_hl_inv(i32 %{{[a-zA-Z0-9_.]+}}, i32 2)
; CHECK:     call i32 @cq_template_add_i32_hl_inv(i32 %{{[a-zA-Z0-9_.]+}}, i32 1)
; CHECK:     call void @cqrt_ry_i32(i32 %{{[a-zA-Z0-9_.]+}}, double -2.500000e-01)
; CHECK:     call void @cqrt_free(i32 %{{[a-zA-Z0-9_.]+}})
;
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
