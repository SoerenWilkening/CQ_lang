; lowering_loop_break_qq.ll — POSITIVE emission (Phase 7.4 Inc 2, epic y05j;
; coverage gap test_C_libtooling-x1t1): a value-arm `break` whose tainted
; condition compares the rail against a SECOND loop-invariant QUBIT `p` (Q==Q),
; rather than against a constant (the lowering_loop_break_{value,add,step,
; unsigned} family — all rail-vs-CONSTANT). A classically-bounded loop whose
; in-place value rail is mutated by `q = q ^ 9` and whose break reads `q == p`:
;
;     int p = cq_theta(pseed, 0.5);  // a second, loop-invariant qubit
;     int q = cq_theta(x, 0.25);
;     for (int i = 0; i < n; i++) {
;         q = q ^ 9;                 // in-place xor rail
;         if (q == p) break;         // TAINTED Q==Q break flag (rail vs p)
;     }
;     return cq_measure(q);
;
; The Q==Q break-cond lowers to the BARE two-handle compare template
; `cq_template_icmp_eq_i32(%rail, %p)` (NO `_hl`/`_lh` suffix — both operands are
; i32 handles) and its void adjoint `cq_template_icmp_eq_i32_unc(out, %rail, %p)`,
; a DISTINCT code path from the `_hl` (handle+literal) form every other break
; fixture exercises. `p` is loop-INVARIANT and never mutated, so the backward
; reverse-play clone of the break-cond (cloneBreakCond, BreakReversePlay.cpp)
; reads the SAME `%p` handle — `fire'` recomputed in the reverse-play matches
; `fire` forward on every amplitude branch.
;
; WHY `p` IS LEFT ALLOCATED, NEVER FREED (the load-bearing rationale — Rule 6/8):
; `p` is NOT disentangled at loop end. The break fires when `rail == p`, so the
; captured/escaping answer EQUALS `p` on every break branch — `out` and `p` are
; ENTANGLED, and `p`'s reduced state is MIXED, not a pure `Ry|0>`. `p` is therefore
; a dirty rail NOT provably `|0>`; it is LEFT ALLOCATED (a Rule-6 safe leak,
; accepted in the qubits-not-scarce regime). Reverse-playing or freeing `p` would
; be a HIDDEN MEASUREMENT that collapses the answer (Rule 6/8) — exactly the silent
; miscompile the PLEAK-NOT below guards against. The whole-DAG uncompute spine
; (runs last) never frees `p` for a principled reason: `isTerminalHandle(%p)` is
; FALSE (the live forward QQ compare consumes `%p` as an operand, ChainWalk.cpp)
; and `%p`'s handle is not in `ControlOwnedRails`, so `p`'s DAG is never recovered.
; This is NOT a bug; it is the Rule-12 coverage lock for the QQ break-cond + its
; reverse-play-clone path, which had zero regression coverage (round-5 review
; 2026-06-28). Verified end-to-end by e2e-slice-loop-break-qq (the only layer
; that LINKS the bare-QQ `cq_template_icmp_eq_i32` fwd + `_unc` for break). NB: a
; QQ break can never emit the `_lh` order (both operands are i32 handles), so the
; bare QQ form is the only reachable shape. The two trailing CHECK-NOT decline
; strings are documentary (`opt` writes diagnostics to stderr, not the `-S` stdout
; FileCheck reads); a regression to a loud decline is still caught — the positive
; CHECKs above fail on the empty stdout `opt` then emits.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s --check-prefix=PLEAK
;
; --- the rail (%h1) + the second qubit p (%h), bound at their alloc points ---
; CHECK: %[[P:[a-z0-9]+]] = call i32 @cqrt_alloc_i32(i32 %pseed)
; CHECK: call void @cqrt_ry_i32(i32 %[[P]], double 5.000000e-01)
; CHECK: %[[RAIL:[a-z0-9]+]] = call i32 @cqrt_alloc_i32(i32 %x)
; --- FORWARD body: in-place rail xor, then the BARE Q==Q compare + its _unc ----
; CHECK: call void @cqrt_xorc_i32(i32 %[[RAIL]], i32 9)
; CHECK: %[[FCMP:[a-z0-9_]+]] = call i32 @cq_template_icmp_eq_i32(i32 %[[RAIL]], i32 %[[P]])
; CHECK: call void @cqrt_toffoli(i32 %[[FCMP]],
; CHECK: call void @cq_template_icmp_eq_i32_unc(i32 %[[FCMP]], i32 %[[RAIL]], i32 %[[P]])
; --- BACKWARD reverse-play clone: the SAME Q==Q compare (rail vs p) + its _unc --
; CHECK: cq.brk.rev:
; CHECK: %[[BCMP:[a-z0-9_]+]] = call i32 @cq_template_icmp_eq_i32(i32 %[[RAIL]], i32 %[[P]])
; CHECK: call void @cqrt_toffoli(i32 %[[BCMP]],
; CHECK: call void @cq_template_icmp_eq_i32_unc(i32 %[[BCMP]], i32 %[[RAIL]], i32 %[[P]])
; --- the inverse rail-mut closes the reverse-play; R/idx freed, out measured ----
; CHECK: call void @cqrt_xorc_i32(i32 %[[RAIL]], i32 9)
; CHECK: cq.brk.tail:
; CHECK: call void @cqrt_free(i32 %cq.brk.R)
; CHECK: call void @cqrt_free(i32 %cq.brk.idx)
; CHECK: call i32 @cqrt_measure_i32(i32 %cq.brk.out)
; CHECK-NOT: cq controlled lowering: loop under quantum control
; CHECK-NOT: cq loop lowering: early break body is not a provable rolled single-rail loop
;
; --- p (the second qubit) is NEVER freed — left allocated-clean (Rule 6) -------
; PLEAK: %[[P2:[a-z0-9]+]] = call i32 @cqrt_alloc_i32(i32 %pseed)
; PLEAK-NOT: cqrt_free(i32 %[[P2]])

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @break_qq(i32 %x, i32 %pseed, i32 %n) {
entry:
  %p = call i32 @cq_theta_si32(i32 %pseed, double 5.000000e-01)   ; second invariant qubit
  %q0 = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  %guard = icmp sgt i32 %n, 0
  br i1 %guard, label %loop, label %exit

loop:                                             ; preds = %entry, %loop
  %i = phi i32 [ 0, %entry ], [ %inext, %loop ]      ; classical induction
  %q = phi i32 [ %q0, %entry ], [ %qn, %loop ]       ; tainted value-mutating rail
  %qn = xor i32 %q, 9                                ; value mutation (tainted)
  %brk = icmp eq i32 %qn, %p                         ; TAINTED Q==Q break flag (rail vs p)
  %inext = add nuw nsw i32 %i, 1
  %bound = icmp eq i32 %inext, %n                    ; CLASSICAL loop bound
  %exit.cond = select i1 %brk, i1 true, i1 %bound    ; FUSED select(brk, true, bound)
  br i1 %exit.cond, label %exit, label %loop

exit:                                             ; preds = %loop, %entry
  %ans = phi i32 [ %q0, %entry ], [ %qn, %loop ]     ; value-class escaping answer
  %m = call i32 @cq_measure_si32(i32 %ans)
  ret i32 %m
}
