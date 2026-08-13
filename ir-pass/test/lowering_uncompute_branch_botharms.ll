; lowering_uncompute_branch_botharms.ll — Phase 5 Step 3 headline (PRD §4
; bullet 3 / IMPLEMENTATION §4.3, decision 2.4). A single rotation-only terminal
; handle whose FORWARD mutation runs in `entry` (the common dominator, exactly
; once on every path), then crosses a classical `i1` branch and is JOINED on both
; arms by a φ-node in `merge` — the canonical "both-arm use" live-range merge.
;
; The φ is a NON-mutating live-range extender (it consumes no register), so its
; block enters FreePoint's post-dominator user set: the nearest common
; post-dominator of {entry, merge} is `merge`, and the SINGLE whole-chain adjoint
; lands there at `getFirstInsertionPt()` — AFTER the φ-node — followed by ONE
; `cqrt_free`. The forward `ry(θ)` ran once on every path, so the single
; `ry(-θ)` at the merge restores the register on every path (net identity); it is
; NOT a per-arm divergent reversal (those are deferred to Step 6, never emitted
; here). Divergent per-arm MUTATING rotations cannot be reversed by one merge
; adjoint and stay rejected; this fixture's divergence is purely the classical
; branch, with the only mutation in the common dominator.
;
; The `opt -verify` RUN line guards that the adjoint + free land AFTER the merge
; block's φ-nodes (insertion-point-vs-φ, PRD §6 / decision 2.4).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
;
; Forward rotation in entry (theta → alloc + ry), once on every path:
; CHECK:     call void @cqrt_ry_i32(i32 %[[H:[a-zA-Z0-9_.]+]], double 2.500000e-01)
;
; The merge block joins the handle on both arms via a φ-node…
; CHECK:     merge:
; CHECK:     phi i32
; …then the SINGLE whole-chain adjoint (SAME symbol, NEGATED angle) lands AFTER
; the φ and restores the register — NOT a divergent per-arm inverse:
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double -2.500000e-01)
; …immediately followed by the SINGLE free of the now-restored handle:
; CHECK:     call void @cqrt_free(i32 %[[H]])
;
; …and there is NO second / divergent inverse, and NO duplicated free:
; CHECK-NOT: call void @cqrt_ry_i32(i32 %[[H]], double -2.500000e-01)
; CHECK-NOT: call void @cqrt_free(i32 %[[H]])
;
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)

define void @slice(i32 %x, i1 %c) {
entry:
  %h = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  br i1 %c, label %a, label %b
a:
  br label %merge
b:
  br label %merge
merge:
  %hp = phi i32 [ %h, %a ], [ %h, %b ]
  ret void
}
