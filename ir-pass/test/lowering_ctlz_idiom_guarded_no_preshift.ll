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
; "the guard is never touched"). Measured, and it is PRE-EXISTING rather than
; caused here:
;
;   * this exact diamond — a tainted-condition if/merge whose sole 2-incoming
;     integer merge phi takes a ConstantInt on the entry edge — declines TODAY,
;     with or without this pass. PredMux reaches the witness stage and leaves it
;     at `gate=W-witness`;
;   * the witness that covers that shape class is W7 (bd 0rwu, the fdlibm
;     `__isnanl` tail), and its clause (e) is a BLANKET "no call anywhere in the
;     region interior". That clause was added by a Rule-13 round to stop W7
;     stealing accepts from the call-based owners (6.5 `classifyClassicalCallArm`,
;     the IO sink, AbortPark, eq-fold's in-arm `cq_phi`), and it is deliberately
;     TAINT-BLIND. The `@llvm.ctlz` this pass substitutes into the arm is a call,
;     so W7 stands down;
;   * widening clause (e) is a change to a reviewed PredMux fence with its own
;     accept-surface and its own Rule-12/13 round. It is NOT in this increment,
;     and doing it as a side effect of a recognizer landing is exactly the kind
;     of quiet scope creep the Prime Directive exists to stop.
;
; So the disposition is a LOUD DECLINE, which is always safe. What matters is
; that the realistic shape is unaffected: lowering_ctlz_idiom_both_loops.ll is
; the same guarded loop in its actual `s_ilogb.c` context (nested inside
; `if (hx == 0)`, three-incoming return merge) and it lowers COMPLETELY — both
; loops claimed, both diamonds flattened, the 4.4 controlled-XOR copy merge
; emitted, no loop and no `br i1` left. The 2-incoming spelling here is the
; minimal isolation of loop A, not the shape the target cell presents.
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
