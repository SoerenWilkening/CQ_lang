; lowering_ctlz_idiom_reject_nested_in_outer_loop.ll — DECLINE (bd ww4c Inc 1,
; the Z1 top-level probe). The accepted idiom, byte for byte, wrapped in an outer
; classical counted loop.
;
; NOT in the PRD §10 matrix. Added during Inc 1 after working the interaction
; through: Z1's `isInnermost` admits a loop that has a PARENT, and every target
; loop measured in PRD §3.1 is top-level, so admitting nested ones buys nothing
; and opens a class nobody has reviewed. Concretely, after a claim the substituted
; chain would sit INSIDE the outer loop and the escaping counter would feed an
; outer accumulator — so a shape whose inner loop declines loudly today (Q1, on
; the inner tainted exit) would instead arrive at `tryCaseA` as an outer loop
; carrying tainted values across iterations. That may well decline too (X1), but
; "may well" is not the standard: the loop campaign is 3-for-3 at finding
; over-accepts in adversarial rounds, one of them AFTER the epic was closed as
; Rule-13 cleared, and the way that record was earned is by shapes exactly this
; plausible.
;
; So Z1 requires a TOP-LEVEL loop, not merely an innermost one. Like every other
; narrowing in PRD §5.2 this is an additive widening owed its own Rule-12/13
; round if a census cell ever needs it, and under Rule 17 it is scope rather than
; evasion because the loops this pass was built for sit inside the accept set.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: loop under quantum control

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @reject_nested(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  br label %outer

outer:                                            ; preds = %entry, %latch
  %i = phi i32 [ 0, %entry ], [ %inext, %latch ]
  %acc = phi i32 [ 0, %entry ], [ %sum, %latch ]
  br label %inner

inner:                                            ; preds = %outer, %inner
  %ix = phi i32 [ -1022, %outer ], [ %dec, %inner ]
  %x = phi i32 [ %q, %outer ], [ %sh, %inner ]
  %dec = add nsw i32 %ix, -1
  %sh = shl nuw i32 %x, 1
  %pos = icmp sgt i32 %sh, 0
  br i1 %pos, label %inner, label %latch

latch:                                            ; preds = %inner
  %sum = add nsw i32 %acc, %dec
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %inext, 4
  br i1 %done, label %exit, label %outer

exit:                                             ; preds = %latch
  %m = call i32 @cq_measure_si32(i32 %sum)
  ret i32 %m
}
