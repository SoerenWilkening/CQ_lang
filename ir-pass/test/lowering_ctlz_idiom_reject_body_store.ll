; lowering_ctlz_idiom_reject_body_store.ll — DECLINE (bd ww4c Inc 1, the Z6
; probe, memory flavour). The accepted shape plus ONE instruction: a CLASSICAL
; store to a global in the loop body.
;
; The store is deliberately classical (a constant to a global, no tainted
; operand) so it does NOT trip `declineTaintEscapes` first. That isolates Z6:
; if the fixture declined via the escape guard it would prove nothing about this
; fence, which is the whole point of a discriminating probe.
;
; The reason a memory access cannot ride along is that the loop's trip count is
; OBSERVABLE through it. The closed form replaces f body executions with a fixed
; four-op chain; f stores become zero stores. The value is right and the program
; is wrong.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: loop under quantum control

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
@ticks = internal global i32 0, align 4

define i32 @reject_body_store(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  br label %loop

loop:                                             ; preds = %entry, %loop
  %ix = phi i32 [ -1022, %entry ], [ %dec, %loop ]
  %x = phi i32 [ %q, %entry ], [ %sh, %loop ]
  %dec = add nsw i32 %ix, -1
  %sh = shl nuw i32 %x, 1
  store i32 1, ptr @ticks, align 4
  %pos = icmp sgt i32 %sh, 0
  br i1 %pos, label %loop, label %exit

exit:                                             ; preds = %loop
  %m = call i32 @cq_measure_si32(i32 %dec)
  ret i32 %m
}
