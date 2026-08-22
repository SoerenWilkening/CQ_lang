; lowering_ctlz_idiom_reject_dead_counter.ll — DECLINE (bd ww4c.4, the Z7
; REQUIRE-THE-ESCAPE probe). The accepted shape with ONE change: the exit block
; measures `%u` instead of `%dec`, so NOTHING leaves the loop.
;
; Z7 does not merely TOLERATE the counter escaping — it REQUIRES it
; (`if (!CounterEscapes) return false;`). That direction is easy to read as a
; formality and it is not: with no out-of-loop user, the substituted four-op
; chain would be DEAD TAINTED ARITHMETIC, and a dead tainted op lowers to a
; forward gate that nobody uncomputes and nobody frees — a dangling entangled
; flag (Rules 6 and 8; bd memory [[orphaned-emitted-gates-three-producers]]).
; The secondary reason is plainer: a loop whose result nobody reads is also
; nobody's coverage, so claiming it buys nothing and risks something.
;
; ISOLATION, by delta pair: change the exit to `cq_measure_si32(i32 %dec)` — one
; operand, nothing else — and the pass claims the loop. So `!CounterEscapes` is
; the sole ground here.
;
; Note the shape is NOT vacuous: `%dec` and the whole recurrence are still live
; INSIDE the loop (the compare reads `%sh`, the phis read `%dec`/`%sh`), so this
; is genuinely "the idiom, computed and discarded", not a loop LLVM would have
; deleted before the pass sees it — `-O1` keeps it because the pass runs on the
; IR as given.
;
; RUN: not env CQ_CTLZ_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK-NOT: CQ_CTLZ_DBG: claiming shift-count loop
; CHECK: error{{.*}}cq controlled lowering: loop under quantum control

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @dead_counter(i32 %u) {
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
  ; Z7: `%dec` has NO out-of-loop user. Swap `%u` -> `%dec` and it is claimed.
  %m = call i32 @cq_measure_si32(i32 %u)
  ret i32 %m
}
