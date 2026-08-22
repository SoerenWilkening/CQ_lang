; lowering_ctlz_idiom_reject_multi_exit.ll — DECLINE (bd ww4c Inc 1, the Z1
; probe). The accepted shape split across TWO blocks with TWO exiting edges: an
; early bail on a bit test, then the shift latch.
;
; Z1 requires a rotated do-while — one latch, one exiting block, and the exiting
; block IS the latch — because PRD §4.1 derives f for THAT control shape and no
; other. Here f is `min(the ctlz answer, the first index where the bit test
; fires)`, which is not the closed form and in general is not a closed form at
; all.
;
; NOTE THE OWNER, because it is NOT Q1 and that was measured, not assumed. A
; second exiting edge is a `break`, so this loop belongs to the y05j family and
; `tryBreak`'s B1 multi-site fence claims it FIRST — the diagnostic is
; `cq loop lowering: multiple early-break sites` (LoopLowering.cpp), pinned below
; character-for-character. That is the correct disposition, not a gap: the loop
; campaign's shipped break fence is E1-E15, grown by 13 recorded over-accept
; holes across THREE adversarial rounds, one of them after the epic had already
; been cleared. Two recognizers claiming the same loop shape is exactly how the
; fourteenth gets found, so this pass stays out of that territory entirely.
;
; The general rule this fixture illustrates: the recognizer is accept-only, so
; "declines" here always mean "some OTHER shipped owner speaks". Which one
; depends on the shape, and each negative fixture pins the one it actually
; reaches rather than assuming Q1.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: multiple early-break sites

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @reject_multi_exit(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  br label %head

head:                                             ; preds = %entry, %latch
  %ix = phi i32 [ -1022, %entry ], [ %dec, %latch ]
  %x = phi i32 [ %q, %entry ], [ %sh, %latch ]
  %dec = add nsw i32 %ix, -1
  %low = and i32 %x, 1
  %bail = icmp eq i32 %low, 1
  br i1 %bail, label %exit, label %latch

latch:                                            ; preds = %head
  %sh = shl nuw i32 %x, 1
  %pos = icmp sgt i32 %sh, 0
  br i1 %pos, label %head, label %exit

exit:                                             ; preds = %head, %latch
  %m = call i32 @cq_measure_si32(i32 %dec)
  ret i32 %m
}
