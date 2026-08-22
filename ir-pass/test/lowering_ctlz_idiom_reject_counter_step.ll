; lowering_ctlz_idiom_reject_counter_step.ll — DECLINE (bd ww4c Inc 1, the Z4
; step probe). The accepted shape with ONE change: the counter INCREMENTS
; (`add %ix, 1`) instead of decrementing.
;
; Z4 requires a ConstantInt step of exactly -1, because the escaping value is
; C0 - f and any other step is a different closed form (C0 +- k*f). The mirror
; case is deliberately the one chosen here: PRD §5.3's table shows `ilogbl` /
; `logbl` counting UP (`%22 = add nuw nsw i32 %20, 1`), so this fixture is the
; SECOND INDEPENDENT GROUND on which that f80 family declines — the first being
; Z5, pinned by lowering_ctlz_idiom_reject_mask_shift_f80.ll. PRD §5.1: two
; independent grounds, on purpose.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: loop under quantum control

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @reject_counter_step(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  br label %loop

loop:                                             ; preds = %entry, %loop
  %ix = phi i32 [ 0, %entry ], [ %inc, %loop ]
  %x = phi i32 [ %q, %entry ], [ %sh, %loop ]
  %inc = add nsw i32 %ix, 1
  %sh = shl nuw i32 %x, 1
  %pos = icmp sgt i32 %sh, 0
  br i1 %pos, label %loop, label %exit

exit:                                             ; preds = %loop
  %m = call i32 @cq_measure_si32(i32 %inc)
  ret i32 %m
}
