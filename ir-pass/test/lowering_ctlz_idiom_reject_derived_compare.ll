; lowering_ctlz_idiom_reject_derived_compare.ll — DECLINE (bd ww4c Inc 1, the Z5
; core probe, and the MINIMAL PAIR for the f80 mask-shift). The accepted shape
; with ONE change: the exit test compares `and %sh, %inv` instead of `%sh`.
;
; Everything else is the accepted idiom — `shl <rec>, 1`, `add <ctr>, -1`,
; predicate `sgt`, constant 0, single latch, nothing else in the body. Only the
; COMPARED OPERAND is derived. Where lowering_ctlz_idiom_reject_mask_shift_f80.ll
; is the real f80 loop declining on four grounds at once, this one isolates Z5's
; clause so the fixture pair proves Z5 ALONE is sufficient. Without that,
; nothing distinguishes "Z5 works" from "one of the other three caught it".
;
; The clause is the termination argument, not a style rule: `%sh` marches
; monotonically into the sign bit, so the loop is bounded by N on every input.
; `and %sh, %inv` does not — this loop diverges whenever %inv is 0.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: loop under quantum control

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @reject_derived_compare(i32 %u, i32 %inv) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  br label %loop

loop:                                             ; preds = %entry, %loop
  %ix = phi i32 [ -1022, %entry ], [ %dec, %loop ]
  %x = phi i32 [ %q, %entry ], [ %sh, %loop ]
  %dec = add nsw i32 %ix, -1
  %sh = shl nuw i32 %x, 1
  %probe = and i32 %sh, %inv
  %pos = icmp sgt i32 %probe, 0
  br i1 %pos, label %loop, label %exit

exit:                                             ; preds = %loop
  %m = call i32 @cq_measure_si32(i32 %dec)
  ret i32 %m
}
