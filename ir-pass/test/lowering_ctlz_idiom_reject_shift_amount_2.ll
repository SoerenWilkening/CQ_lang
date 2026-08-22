; lowering_ctlz_idiom_reject_shift_amount_2.ll — DECLINE (bd ww4c Inc 1, the Z3
; stride probe). The accepted shape with ONE change: the shift amount is 2.
;
; Z3 requires the amount to be a ConstantInt EXACTLY 1. Stride != 1 is not the
; same loop with a scale factor: it has a genuinely different closed form
; (roughly ceil(ctlz/stride)), and bd 19v3 measured SCEV reporting a max trip of
; 32 for strides 1/2/16/31 whose TRUE maxima are 31/16/2/1 — a naive recognizer
; is wrong in both directions here, which is why this is a fence and not a
; normalisation.
;
; PRD §5.2: widening to stride != 1 is additive and mechanical, and is scope
; rather than evasion — the three target loops all sit inside the accept set at
; stride 1, so Rule 17's test ("is a decline being substituted for work we set
; out to do?") is not met. It would need its own Rule-12/13 round.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: loop under quantum control

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @reject_stride2(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  br label %loop

loop:                                             ; preds = %entry, %loop
  %ix = phi i32 [ -1022, %entry ], [ %dec, %loop ]
  %x = phi i32 [ %q, %entry ], [ %sh, %loop ]
  %dec = add nsw i32 %ix, -1
  %sh = shl nuw i32 %x, 2
  %pos = icmp sgt i32 %sh, 0
  br i1 %pos, label %loop, label %exit

exit:                                             ; preds = %loop
  %m = call i32 @cq_measure_si32(i32 %dec)
  ret i32 %m
}
