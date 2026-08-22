; lowering_ctlz_idiom_guarded_no_preshift.ll — CLAIMED, then declined BY A
; DIFFERENT OWNER (bd ww4c Inc 1). The `s_ilogb.c:40` loop in isolation: the only
; one of the three target loops that still carries its source guard (`icmp sgt
; %lx, 0`, whose bypass runs straight to the return merge with the un-decremented
; C0), and the only one with no pre-shift. Pair partner of
; lowering_ctlz_idiom_unguarded_preshift.ll — together they are PRD §5.4's
; accept-invariance pin: the recognizer sees the loop ALONE, so both spellings
; are claimed identically and the guard is nobody's business here.
;
; WHY THIS IS A `not` FIXTURE, AND WHY THAT IS NOT A GAP IN THIS PASS. The loop
; IS claimed — the CQ_CTLZ_DBG line below is the assertion, and it fires with
; C0 = -1043, so the emitted constant would be -1044. What then declines is the
; ENCLOSING GUARD DIAMOND, which this pass deliberately never touches (PRD §4.6:
; "the guard is never touched").
;
; ⚠ CORRECTED 2026-08-22 (bd ww4c.3 adversarial round). This block previously
; said the diamond "declines TODAY, with or without this pass" and that PredMux
; "reaches the witness stage and leaves it at `gate=W-witness`" either way. BOTH
; HALVES ARE FALSE, and the correction is the point of keeping the paragraph.
; Re-measured with `CQ_PREDMUX_DBG=1 CQ_CTLZ_DBG=1` on this exact fixture:
;
;     leave @ilogb_lx_loop entry=entry merge=merge gate=E2-cycle    <- BEFORE
;     leave @ilogb_lx_loop entry=loop  merge=merge gate=W-witness
;     CQ_CTLZ_DBG: claiming shift-count loop in @ilogb_lx_loop (i32, C0=i32 -1043)
;     leave @ilogb_lx_loop entry=entry merge=merge gate=W-witness   <- AFTER
;
; The region's gate MOVES `E2-cycle` -> `W-witness` ACROSS the claim: before the
; rewrite it never reached the witness stage at all, because it still contained
; the loop. So the `@llvm.ctlz` substituted here is the PROXIMATE AND SOLE cause
; of the W7 stand-down — this decline is caused here, not inherited. The function
; declines either way (Q1 `loop` before, ControlDetect `control flow` after), so
; nothing is unsound and the fixture's assertions are unchanged; what was wrong
; was the recorded REASON, which is how a wrong mental model gets quoted later.
;
;   * the witness that covers this shape class is W7 (bd 0rwu, the fdlibm
;     `__isnanl` tail), and its clause (e) is a BLANKET "no call anywhere in the
;     region interior" (PredMuxFlatten.cpp:2360-2373). That clause was added by a
;     Rule-13 round to stop W7 stealing accepts from the call-based owners (6.5
;     `classifyClassicalCallArm`, the IO sink, AbortPark, eq-fold's in-arm
;     `cq_phi`), and it is deliberately TAINT-BLIND — a blanket `isa<CallInst>`
;     with no callee, attribute or intrinsic exception. `@llvm.ctlz` is an
;     IntrinsicInst, hence a CallInst, so W7 stands down;
;   * widening clause (e) is a change to a reviewed PredMux fence with its own
;     accept-surface and its own Rule-12/13 round. It is NOT in this increment,
;     and doing it as a side effect of a recognizer landing is exactly the kind
;     of quiet scope creep the Prime Directive exists to stop. Tracked separately.
;
; THE PRECONDITION THAT DECIDES WHICH WAY A CALLER GOES IS MERGE-PHI ARITY, AND
; Z1-Z9 DOES NOT CHECK IT (measured 2026-08-22, bd ww4c.3). W7's own gate at
; PredMuxFlatten.cpp:2306 requires `NumMergePhis == 1 && SolePhiIncomings == 2`,
; so clause (e) can only ever fire on a TWO-incoming merge — which is exactly
; this fixture (`phi i32 [ -1043, %entry ], [ %dec, %loop ]`). A merge with MORE
; than two incomings rides a different disjunct of the same `Claim` expression,
; `(NumMergePhis == 1 && SolePhiIncomings > 2)` at :2485, and THAT disjunct
; carries NO call fence at all. That is why the real cells are unaffected:
; measured on their stage-1 IR, `ilogb.f64`'s return merge has SIX incomings and
; `ilogbf.f32`'s has FOUR, so W7 is never even consulted for them.
;
; So the disposition is a LOUD DECLINE, which is always safe, and the realistic
; shape is unaffected: lowering_ctlz_idiom_both_loops.ll is the same guarded loop
; in its actual `s_ilogb.c` context (nested inside `if (hx == 0)`, three-incoming
; return merge) and it lowers COMPLETELY — both loops claimed, both diamonds
; flattened, the 4.4 controlled-XOR copy merge emitted, no loop and no `br i1`
; left; and both real cells reach `opt` exit 0 with committed goldens
; (tests/e2e/slice_libm_real_ilogb{,f}.c). The 2-incoming spelling here is the
; minimal isolation of loop A, not the shape any target cell presents — but it is
; a REAL residual limit on the caller's shape, not a fixture artifact, and it is
; the thing to reach for first if a future cell claims and then declines.
;
; RUN: not env CQ_CTLZ_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
;
; The loop IS claimed, at the right width and the right seed...
; CHECK: CQ_CTLZ_DBG: claiming shift-count loop in @ilogb_lx_loop (i32, C0=i32 -1043)
; ...and what declines is the enclosing diamond, not the loop: the message is
; ControlDetect's `control flow`, NOT `tryCaseA`'s Q1 `loop`. If this ever
; regressed to the Q1 message the recognizer would have stopped claiming.
; CHECK: error{{.*}}cq controlled lowering: control flow under quantum control
; CHECK-NOT: cq controlled lowering: loop under quantum control

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @ilogb_lx_loop(i32 %u) {
entry:
  %lx = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %g = icmp sgt i32 %lx, 0
  br i1 %g, label %loop, label %merge

loop:                                             ; preds = %entry, %loop
  %ix = phi i32 [ -1043, %entry ], [ %dec, %loop ]
  %x = phi i32 [ %lx, %entry ], [ %sh, %loop ]
  %dec = add nsw i32 %ix, -1
  %sh = shl nuw i32 %x, 1
  %pos = icmp sgt i32 %sh, 0
  br i1 %pos, label %loop, label %merge, !llvm.loop !0

merge:                                            ; preds = %entry, %loop
  %r = phi i32 [ -1043, %entry ], [ %dec, %loop ]
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

!0 = distinct !{!0, !1}
!1 = !{!"llvm.loop.mustprogress"}
