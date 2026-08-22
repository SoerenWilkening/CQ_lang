; lowering_ctlz_idiom_reject_escaping_counter_phi.ll — DECLINE (bd ww4c.4, the Z7
; COUNTER-PHI probe). The accepted shape with ONE change: the exit block reads
; `%ix` — the counter PHI — as well as `%dec`, its latch value.
;
; Z7's escape analysis is directional and this is the direction that had no
; fixture. `lowering_ctlz_idiom_reject_escaping_shift.ll` pins the SHIFT register
; escaping; nothing pinned the COUNTER PHI escaping, even though the two are
; different values with different closed forms:
;   %dec (the latch value)  escapes as  c_exit = C0 - f          <- what we emit
;   %ix  (the phi)          escapes as  C0 - (f - 1)             <- one less
; so a fence that let `%ix` out would need a SECOND closed form, and RAUW'ing
; only `%dec` would leave `%ix` reading an erased value. It declines instead:
; `noEscapingUse(R.CountPhi, L)` requires the phi to have no out-of-loop user at
; all, which is the conservative half of the same clause that REQUIRES `%dec` to
; have one.
;
; ISOLATION, by delta pair: change the exit's `add i32 %ix, %dec` to
; `add i32 %dec, 0` — the phi stops escaping, `%dec` still does — and the pass
; claims the loop. So `noEscapingUse(CountPhi)` is the sole ground.
;
; This is a deferred widening, not a punt (PRD §5.2 / Rule 17): the target loops
; do not escape their counter phi, so they sit inside the accept set. If a future
; census cell needs it, `C0 - (f-1)` is a one-line second emission owed its own
; Rule-12/13 round.
;
; RUN: not env CQ_CTLZ_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK-NOT: CQ_CTLZ_DBG: claiming shift-count loop
; CHECK: error{{.*}}cq controlled lowering: loop under quantum control

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @escaping_counter_phi(i32 %u) {
entry:
  %hx = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  br label %loop

loop:                                             ; preds = %entry, %loop
  %ix = phi i32 [ -1022, %entry ], [ %dec, %loop ]
  %x = phi i32 [ %hx, %entry ], [ %sh, %loop ]
  %dec = add nsw i32 %ix, -1
  %sh = shl nuw i32 %x, 1
  %pos = icmp sgt i32 %sh, 0
  br i1 %pos, label %loop, label %exit

exit:                                             ; preds = %loop
  ; Z7: `%ix` (the counter PHI) escapes here alongside `%dec`. Replace this with
  ; `add i32 %dec, 0` and the loop is claimed.
  %s = add i32 %ix, %dec
  %m = call i32 @cq_measure_si32(i32 %s)
  ret i32 %m
}
