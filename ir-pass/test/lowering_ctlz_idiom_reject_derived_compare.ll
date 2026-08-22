; lowering_ctlz_idiom_reject_derived_compare.ll — DECLINE (bd ww4c Inc 1, the Z5
; core probe, and the MINIMAL PAIR for the f80 mask-shift). The accepted shape
; with ONE change: the exit test compares the PHI (`%x`) instead of the
; recurrence's own latch value (`%sh`).
;
; *** THE SPELLING HERE IS LOAD-BEARING AND WAS CORRECTED IN Inc 3 (bd ww4c.4).
; The original fixture compared `and %sh, %inv`, which needed a SEVENTH
; instruction in the loop body — so Z6 ("exactly six, no seventh") rejected it
; too, and the fixture declined on TWO grounds while its header claimed to
; isolate one. Because the pass is ACCEPT-ONLY and never diagnoses, the two
; grounds are indistinguishable from outside: the old fixture could not tell you
; which fence fired, so it did not prove what it claimed (Rule 12). Comparing the
; phi costs no instructions — the body stays at exactly six — so Z6 passes and
; Z5 is the SOLE remaining ground. ***
;
; ISOLATION PROVEN BY PERTURBATION, which is the only proof available for an
; accept-only pass: changing `%x` back to `%sh` on line 41 — one token, nothing
; else — makes the pass CLAIM this loop (`CQ_CTLZ_DBG: claiming shift-count loop
; in @reject_derived_compare`). A one-token accept<->decline flip pins exactly
; one clause and nothing else.
;
; Z5 is implemented as `Cmp->getOperand(0) != R.Shl`, so comparing the phi trips
; it and only it. That spelling is also the UN-ROTATED `while` loop, so this
; fixture doubles as the rotation pin.
;
; Where lowering_ctlz_idiom_reject_mask_shift_f80.ll is the real f80 loop
; declining on many grounds at once, this one isolates Z5's compared-operand
; clause, so the pair proves Z5 ALONE is sufficient rather than merely
; co-occurring with the others.
;
; The clause is the termination argument, not a style rule: `%sh` marches
; monotonically into the sign bit, so the loop is bounded by N on every input. A
; value merely DERIVED from it has no such property — which is exactly how
; `ilogbl`'s `and <recurrence>, <invariant data>` diverges when the tested word
; is 0.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: loop under quantum control

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @reject_derived_compare(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  br label %loop

loop:                                             ; preds = %entry, %loop
  %ix = phi i32 [ -1022, %entry ], [ %dec, %loop ]
  %x = phi i32 [ %q, %entry ], [ %sh, %loop ]
  %dec = add nsw i32 %ix, -1
  %sh = shl nuw i32 %x, 1
  ; Z5: the compared operand is the PHI, not `%sh`. Six instructions exactly, so
  ; Z6 passes and this is the SOLE ground. Flip `%x` -> `%sh` and it is claimed.
  %pos = icmp sgt i32 %x, 0
  br i1 %pos, label %loop, label %exit

exit:                                             ; preds = %loop
  %m = call i32 @cq_measure_si32(i32 %dec)
  ret i32 %m
}
