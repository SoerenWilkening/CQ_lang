; lowering_ctlz_idiom_reject_three_phis.ll — DECLINE (bd ww4c Inc 1, the Z2
; probe). The accepted shape plus ONE loop-carried value: a third header phi
; accumulating the shifted words.
;
; Z2 admits exactly two header phis — a shift recurrence and a counter — because
; those are the only two the PRD §4.1 closed form describes. A third loop-carried
; value is a value we have no closed form for, and collapsing the loop would drop
; it. Note this fixture ALSO fails Z6 (the extra `xor` in the body) and Z7 (the
; accumulator escapes): the fences overlap by design, and PRD §5.1 says so
; explicitly.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: loop under quantum control

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @reject_three_phis(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  br label %loop

loop:                                             ; preds = %entry, %loop
  %ix = phi i32 [ -1022, %entry ], [ %dec, %loop ]
  %x = phi i32 [ %q, %entry ], [ %sh, %loop ]
  %acc = phi i32 [ 0, %entry ], [ %mix, %loop ]
  %dec = add nsw i32 %ix, -1
  %sh = shl nuw i32 %x, 1
  %mix = xor i32 %acc, %sh
  %pos = icmp sgt i32 %sh, 0
  br i1 %pos, label %loop, label %exit

exit:                                             ; preds = %loop
  %sum = add nsw i32 %dec, %mix
  %m = call i32 @cq_measure_si32(i32 %sum)
  ret i32 %m
}
