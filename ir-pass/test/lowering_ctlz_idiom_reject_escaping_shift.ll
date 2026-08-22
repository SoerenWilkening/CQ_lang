; lowering_ctlz_idiom_reject_escaping_shift.ll — DECLINE (bd ww4c Inc 1, the Z7
; probe). The accepted shape with ONE change: the SHIFT RECURRENCE also escapes
; the loop (a second exit-block use), so two values leave instead of one.
;
; Z7 admits exactly one escaping value, the counter's latch value, because that
; is the only one the closed form computes. An escaping shift register would owe
; a SECOND closed form, v << f — derivable (f is already in hand), but not
; derived, not reviewed and not tested. Deferred deliberately, not silently
; dropped: PRD §5.2 lists it as an additive widening owed its own Rule-12/13
; round.
;
; The failure mode this prevents is concrete, and it is PRD §7 item 3: the
; mutation RAUWs the escaping counter and erases the loop's SSA. A second
; escaping value the fence did not account for would be left dangling — or worse,
; rewritten to a value that means something else.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: loop under quantum control

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @reject_escaping_shift(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  br label %loop

loop:                                             ; preds = %entry, %loop
  %ix = phi i32 [ -1022, %entry ], [ %dec, %loop ]
  %x = phi i32 [ %q, %entry ], [ %sh, %loop ]
  %dec = add nsw i32 %ix, -1
  %sh = shl nuw i32 %x, 1
  %pos = icmp sgt i32 %sh, 0
  br i1 %pos, label %loop, label %exit

exit:                                             ; preds = %loop
  %both = add nsw i32 %dec, %sh
  %m = call i32 @cq_measure_si32(i32 %both)
  ret i32 %m
}
