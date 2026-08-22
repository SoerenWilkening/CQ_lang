; lowering_ctlz_idiom_reject_two_preds.ll — DECLINE (bd ww4c.4, the Z1
; UNIQUE-OUT-OF-LOOP-PREDECESSOR probe). The accepted shape with ONE change: the
; loop is entered from TWO distinct out-of-loop blocks, %a and %b.
;
; `L->getLoopPredecessor()` returns null when the header has more than one
; DISTINCT predecessor outside the loop, and that null is what declines here.
; The clause had no fixture, which mattered because Z1 is the one place the
; implementation is deliberately WEAKER than PRD §5 — it asks for a unique
; out-of-loop PREDECESSOR rather than a dedicated PREHEADER, precisely so the
; guarded `s_ilogb.c:40` target loop (which has no preheader at -O1) is not lost.
; A relaxation with no decline fixture is a relaxation nobody can bound later.
;
; WHY UNIQUENESS IS LOAD-BEARING, not hygiene. The emitter reads the phis'
; incomings FOR THAT ONE BLOCK and inserts the substituted chain in the HEADER,
; using `EntryVal` — the shift phi's incoming from PH. The soundness argument is
; that PH being the unique out-of-loop predecessor makes every path into the
; header cross PH's terminator, and LLVM requires a phi's incoming to dominate
; that terminator, so `EntryVal` dominates the insertion point. With TWO entry
; edges there is no single such value: `%hx` here happens to be common to both,
; but the fence cannot know that in general, and picking either block's incoming
; would be wrong whenever they differ.
;
; ISOLATION, by delta pair (verified: the delta below is valid IR and IS claimed):
; replace `br i1 %c, label %a, label %b` with `br label %a`, delete the %b block,
; and drop its two now-dead phi incomings. That is FOUR textual edits for ONE
; semantic change — removing an entry edge necessarily removes the block and its
; phi entries, and leaving %b in place would keep it a predecessor (unreachable
; blocks still count), so a smaller edit does not exist.
;
; RUN: not env CQ_CTLZ_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK-NOT: CQ_CTLZ_DBG: claiming shift-count loop
; CHECK: error{{.*}}cq controlled lowering: loop under quantum control

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @two_preds(i32 %u, i1 %c) {
entry:
  %hx = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  br i1 %c, label %a, label %b

a:                                                ; preds = %entry
  br label %loop

b:                                                ; preds = %entry
  br label %loop

loop:                                             ; preds = %a, %b, %loop
  ; THREE incomings: two out-of-loop entries plus the latch. `getLoopPredecessor`
  ; returns null, so Z1 declines before Z2 ever counts them.
  %ix = phi i32 [ -1022, %a ], [ -1022, %b ], [ %dec, %loop ]
  %x = phi i32 [ %hx, %a ], [ %hx, %b ], [ %sh, %loop ]
  %dec = add nsw i32 %ix, -1
  %sh = shl nuw i32 %x, 1
  %pos = icmp sgt i32 %sh, 0
  br i1 %pos, label %loop, label %exit

exit:                                             ; preds = %loop
  %m = call i32 @cq_measure_si32(i32 %dec)
  ret i32 %m
}
