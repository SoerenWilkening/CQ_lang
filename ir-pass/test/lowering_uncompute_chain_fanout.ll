; lowering_uncompute_chain_fanout.ll — Phase 5 Step 2 fan-out guard (invariant).
; ChainWalk's whole-chain reversal assumes a LINEAR register lineage. When an
; intermediate handle fans out — here `%h1` feeds BOTH `%h2 = h1 + 1` and
; `%h3 = h1 * 2` — there are two dead terminals (`%h2`, `%h3`) whose recovered
; chains SHARE the upstream gates (`cqrt_ry`, `add_1`). Reversing each terminal
; independently would uncompute the shared prefix twice (and before the sibling
; branch's use). Step 2 is conservative: it detects the shared (multi-consumer)
; lineage handle and emits NOTHING for either terminal (true DAG/tree reversal is
; deferred to a later step). This fixture LOCKS that no-emit behavior.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; The forward lowering still happens (the fan-out is in the data, not the lowering):
; CHECK:     call i32 @cq_template_add_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 1)
; CHECK:     call i32 @cq_template_mul_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 2)
;
; But this conservative slice must NOT uncompute the shared chain: no void `_unc`
; adjoint (the spine's uncompute form after WI-3), no free. (WI-4 replaces this
; no-emit lock with a real reversed-DAG check.)
; CHECK-NOT: cq_template_add_i32_hl_unc
; CHECK-NOT: cq_template_mul_i32_hl_unc
; CHECK-NOT: cqrt_free
;
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)

define void @slice(i32 %x) {
entry:
  %h = call i32 @cq_theta_si32(i32 %x, double 1.000000e-01)
  %h1 = add i32 %h, 1
  %h2 = add i32 %h1, 1
  %h3 = mul i32 %h1, 2
  ret void
}
