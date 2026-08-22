; lowering_ctlz_idiom_reject_inverted_successors.ll — DECLINE (bd ww4c Inc 1, the
; Z5 polarity-normalisation probe). NOT in the PRD §10 matrix; added because PRD
; §7 item 2 names this exact residual risk — "a spelling where the
; continue-condition normalisation in Z5 admits a loop whose exit test is not
; what it looks like" — and a risk named in the PRD with no fixture is a risk
; nobody measured.
;
; It is the MINIMAL PAIR of lowering_ctlz_idiom_inverted_polarity.ll. Both have
; the loop as the FALSE successor; they differ only in the predicate:
;
;     accepted : icmp sle %sh, 0 ; br i1 %c, label %exit, label %loop
;     HERE     : icmp sgt %sh, 0 ; br i1 %c, label %exit, label %loop
;
; Normalising the CONTINUE condition — invert the predicate when the loop is the
; false successor — makes the accepted one `sgt 0` and this one `sle 0`. So this
; loop continues while %sh <= 0, which is a completely different program: it does
; not terminate (0 shifts to 0; -1 shifts to -2 to -4 ... and stays negative
; until it reaches 0, then stays there forever).
;
; An implementation that matched the branch as WRITTEN, ignoring which successor
; is the back edge, would accept this and substitute a finite four-op chain for
; an infinite loop. That is the failure mode this pass has instead of a wrong
; decline: a WRONG CLAIM.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: loop under quantum control

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @reject_inverted_successors(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  br label %loop

loop:                                             ; preds = %entry, %loop
  %ix = phi i32 [ -1022, %entry ], [ %dec, %loop ]
  %x = phi i32 [ %q, %entry ], [ %sh, %loop ]
  %dec = add nsw i32 %ix, -1
  %sh = shl nuw i32 %x, 1
  %pos = icmp sgt i32 %sh, 0
  br i1 %pos, label %exit, label %loop

exit:                                             ; preds = %loop
  %m = call i32 @cq_measure_si32(i32 %dec)
  ret i32 %m
}
