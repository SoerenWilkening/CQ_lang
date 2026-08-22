; lowering_ctlz_idiom_reject_counter_width_mismatch.ll — DECLINE (bd ww4c.4, the
; Z9 SAME-WIDTH probe). The accepted shape with ONE change: the counter
; recurrence is i64 while the shift recurrence stays i32.
;
; THIS IS THE MOST LOAD-BEARING OF THE FIVE Rule-12 gaps Inc 3 closed, and the
; reason is not semantic tidiness. `CtlzIdiomPrepass.h` singles this clause out
; as a deliberate NARROWING, i.e. a named accept-predicate — Rule 12 requires
; every one of those to ship with a decline fixture, and this one shipped without
; any fixture in the tree exercising a mixed-width recurrence/counter at all.
;
; WHAT IT PREVENTS, concretely — the emitter builds the seed and rewrites the
; escapee at the RECURRENCE'S width:
;   ConstantInt::get(R.Ty, R.C0->getValue() - 1)   <- R.Ty is the SHIFT's type
;   R.Dec->replaceAllUsesWith(C)                   <- C is at R.Ty, %dec is i64
; so without Z9's same-width clause this loop would build a `sub` whose operands
; disagree in width and perform a CROSS-TYPE RAUW. Both LLVM sites guard that
; with `assert` ONLY — and this project's toolchain has assertions compiled OFF
; (measured: `llvm-config --assertion-mode --build-mode` -> OFF / Release), so
; the failure mode is not a loud abort but SILENT MALFORMED IR. Rule 2's whole
; point: `opt -verify` would be the thing that eventually noticed, and by then
; the golden could not tell you why.
;
; ISOLATION, by delta pair: widening BOTH recurrences to i32 (`%ix`/`%dec` i32
; and the exit's `trunc` dropped) makes the pass CLAIM this loop. So Z9's
; same-width clause is the sole ground here — nothing else in the body changes.
; Its minimal ACCEPT pair is lowering_ctlz_idiom_i64.ll @widened_seed, where both
; recurrences are i64 together and the cast sits OUTSIDE the loop.
;
; RUN: not env CQ_CTLZ_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK-NOT: CQ_CTLZ_DBG: claiming shift-count loop
; CHECK: error{{.*}}cq controlled lowering: loop under quantum control

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i64 @counter_width_mismatch(i32 %u) {
entry:
  %hx = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  br label %loop

loop:                                             ; preds = %entry, %loop
  ; Z9: the counter is i64, the shift recurrence i32. Same-width -> claimed.
  %ix = phi i64 [ -1022, %entry ], [ %dec, %loop ]
  %x = phi i32 [ %hx, %entry ], [ %sh, %loop ]
  %dec = add nsw i64 %ix, -1
  %sh = shl nuw i32 %x, 1
  %pos = icmp sgt i32 %sh, 0
  br i1 %pos, label %loop, label %exit

exit:                                             ; preds = %loop
  %t = trunc i64 %dec to i32
  %m = call i32 @cq_measure_si32(i32 %t)
  %z = zext i32 %m to i64
  ret i64 %z
}
