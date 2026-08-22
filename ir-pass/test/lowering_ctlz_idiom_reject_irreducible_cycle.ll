; lowering_ctlz_idiom_reject_irreducible_cycle.ll — DECLINE. THE bd ww4c.4
; OVER-ACCEPT PROBE: the shape the Inc-3 Rule-13 round CLAIMED before Z1(c)
; landed, and the fourth consecutive over-accept this loop campaign's adversarial
; rounds have found.
;
; THE DEFECT, in one sentence: Z1's "TOP-LEVEL" test is `L->getParentLoop()`, a
; LOOPINFO property, and LoopInfo models only NATURAL loops — a back edge u->v
; where v DOMINATES u. An IRREDUCIBLE cycle has no back edge, so LoopInfo reports
; no loop for it at all, `getParentLoop()` returns null and `isInnermost()` is
; true, even though the idiom's header sits inside a cycle.
;
; WHY THIS FUNCTION IS IRREDUCIBLE: `entry` branches to BOTH %A and %B, so
; neither dominates the other, so the cycle A -> pre -> scan -> out -> B -> A has
; two entry points and no single header. LLVM agrees — measured:
;   $ opt -passes='print<loops>' -disable-output <this file>
;   Loop info for function 'irr2':
;   Loop at depth 1 containing: %scan<header><latch><exiting>
; Exactly one loop, and it is reported at DEPTH 1, i.e. top-level.
;
; WHAT THE CLAIM DID, before the fix: it put the four-op closed-form chain INSIDE
; the cycle — `shl`/`ctlz`/`and`/`sub` re-executed and re-allocating a rail on
; every traversal — with the escaping counter feeding an outer accumulator. That
; is verbatim the class Z1's own comment declares unreviewed: "an outer loop
; carrying tainted values across iterations, adjudicated by owners nobody looked
; at for this."
;
; THE A/B TWIN, which is what makes this an over-accept rather than a curiosity:
; change `shl nuw i32 %w, 1` to `shl nuw i32 %w, 2` — ONE TOKEN, taking the loop
; off-fence via Z3 — and the SAME module declines loudly at Q1. So before Z1(c)
; the recognizer converted a loud decline into a silent accept, which is the
; Prime Directive's one unforgivable direction. That twin is also the isolation
; proof: this file declines on Z1(c) and nothing else, because every other clause
; passes (the twin is claimed the moment Z1(c) is not the blocker... and with
; Z1(c) present both halves decline, the fence having done its job).
;
; NOTE the honest limit, recorded so nobody over-quotes this fixture: no WRONG
; VALUE was demonstrated for the claimed shape, and tainted arithmetic inside an
; irreducible cycle is a pre-existing accepted class independent of this pass.
; The defect is that the fence admitted a shape its own contract excludes and
; that nobody reviewed — not that a unitary was proven wrong. Over-declining it
; is free; over-accepting it is the bug.
;
; RUN: not env CQ_CTLZ_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
;
; The loop is NEVER CLAIMED — this is the assertion that would have failed before
; Z1(c), and it is the one that matters. It must precede the error CHECK because
; the debug line is printed at claim time, i.e. before any diagnostic.
; CHECK-NOT: CQ_CTLZ_DBG: claiming shift-count loop
; ...and the pre-existing owner declines it, character for character.
; CHECK: error{{.*}}cq controlled lowering: loop under quantum control
; CHECK-NOT: CQ_CTLZ_DBG: claiming shift-count loop

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @irr2(i32 %u, i1 %c1, i1 %c2) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 1.250000e-01)
  ; The two-way entry is what makes the cycle below irreducible: neither %A nor
  ; %B dominates the other, so the cycle has no single header and LoopInfo does
  ; not model it.
  br i1 %c1, label %A, label %B

A:                                                ; preds = %entry, %B
  br label %pre

pre:                                              ; preds = %A
  br label %scan

; Structurally this IS the accepted idiom, byte for byte — two phis, `shl <rec>,
; 1`, `add <ctr>, -1`, `icmp sgt <latch value>, 0`, six instructions, one escapee,
; tainted entry value, i32. Only its position inside the cycle disqualifies it.
scan:                                             ; preds = %pre, %scan
  %k = phi i32 [ 0, %pre ], [ %dec, %scan ]
  %w = phi i32 [ %q, %pre ], [ %sh, %scan ]
  %dec = add nsw i32 %k, -1
  %sh = shl nuw i32 %w, 1
  %pos = icmp sgt i32 %sh, 0
  br i1 %pos, label %scan, label %out

out:                                              ; preds = %scan
  %m0 = call i32 @cq_measure_si32(i32 %dec)
  br label %B

B:                                                ; preds = %entry, %out
  br i1 %c2, label %A, label %done

done:                                             ; preds = %B
  ret i32 0
}
