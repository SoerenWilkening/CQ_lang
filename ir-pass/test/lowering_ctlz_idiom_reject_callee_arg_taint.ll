; lowering_ctlz_idiom_reject_callee_arg_taint.ll — DECLINE (bd ww4c.4, the Z8
; ARGUMENT-TAINT boundary). The accepted idiom, byte for byte, hosted in a CALLEE
; whose taint arrives ONLY through the call argument.
;
; WHY THIS FIXTURE EXISTS AT ALL — it pins a claim that had hardened into shipped
; source prose without ever being measured into a test. Inc 3 added to
; CtlzIdiomPrepass.cpp the assertion that "an idiom loop hosted in a CALLEE, whose
; taint arrives only through the call argument, is NEVER CLAIMED". That sentence
; is TRUE (measured), but a true sentence in a comment with no fixture behind it
; is exactly the fenv-prose failure mode CLAUDE.md warns about: an
; agent-authored justification that hardens by repetition into a de-facto
; guarantee. This file is the guarantee.
;
; THE MECHANISM, which is an ORDERING fact and not a fence clause: Z8 tests
; `taint.Tainted.count(EntryVal)`, and the ctlz prepass runs BEFORE
; `detectSpecializations`. ARGUMENT taint is minted by `detectSpecializations`,
; which runs after this fixpoint and never re-triggers it. So at the moment Z8
; asks, `%v` is not tainted — the fence declines, silently and correctly, and the
; loop is left to its existing owner. Phase 6 then lifts the callee, and the
; clone declines LOUDLY on its tainted control flow.
;
; NOTE THE DIAGNOSTIC IS ON THE CLONE, `@__cq_q_callee_1`, not on `@callee` — that
; is the shape to expect and it is asserted below.
;
; This is an ACCEPT-SET BOUNDARY, not a defect: over-declining is always safe
; (Prime Directive), the two shipped cells host their loops in the function that
; owns the taint, and nothing here is unsound. It is recorded because it bounds
; what a later reader may assume "Z8 reads settled taint" means — it reads taint
; settled through the fp80-union and PredMux fixpoints, which is a STRICTLY
; SMALLER set than `lowerLoops`/`tryCaseA` later see.
;
; WIDENING PATH, if a census cell ever needs it: re-run the ctlz fixpoint after
; `detectSpecializations` (and re-propagate), which would let the clone's argument
; taint reach Z8. That is additive surface owed its own Rule-12/13 round — do not
; do it as a side effect of something else.
;
; ISOLATION: hoisting the `cq_theta` INTO `@callee` (so the taint is intraprocedural)
; makes the pass claim the loop — see lowering_ctlz_idiom_generic_seed.ll, which is
; that same body with a local taint source.
;
; RUN: not env CQ_CTLZ_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
;
; The fence NEVER claims it — this is the assertion that matters.
; CHECK-NOT: CQ_CTLZ_DBG: claiming shift-count loop
; ...and Phase 6 declines the clone, character for character.
; CHECK: error{{.*}}cq specialization: callee contains tainted control flow under quantum lift
; CHECK-NOT: CQ_CTLZ_DBG: claiming shift-count loop

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

; Structurally the accepted idiom in every respect — two phis, `shl <rec>, 1`,
; `add <ctr>, -1`, `icmp sgt <latch value>, 0`, six instructions, one escapee,
; i32, top-level, not in a cycle. ONLY the provenance of the taint differs.
define internal i32 @callee(i32 %v) {
entry:
  br label %scan

scan:                                             ; preds = %entry, %scan
  %k = phi i32 [ -1022, %entry ], [ %dec, %scan ]
  %w = phi i32 [ %v, %entry ], [ %sh, %scan ]
  %dec = add nsw i32 %k, -1
  %sh = shl nuw i32 %w, 1
  %pos = icmp sgt i32 %sh, 0
  br i1 %pos, label %scan, label %out

out:                                              ; preds = %scan
  ret i32 %dec
}

define i32 @caller(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 1.250000e-01)
  %r = call i32 @callee(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
