; loop_acc_reject_narrow_width.ll — DECLINE, AN INTERIM GAP PIN (bd
; test_C_libtooling-01po.19.18, condition (A5) of LoopAccumulator.h).
;     unsigned char c = 0; for (i < n) c += q;   // i8 phi, add i8
; The accumulator is built for the handle-ABI width `i32` only: the collapse
; RAUWs the phi onto the `i32` register, and a narrower/wider phi would leave its
; readers ill-typed until `lowerOps` (the loop-carried-handle promotion needs its
; P4 user gate for the same retype). So the X1 decline stands for `i8`, loudly.
; RETIREMENT TRIGGER: the width follow-up of bd 01po.19.18 (retype + HandleWidth,
; as `promoteLoopCarriedHandleSeeds` does) turns this into an accept — move it
; to loop_acc_seeded_accept.ll then; the `_Bool` parity (`icmp ne` spelling of
; xor) rides the same follow-up.
;
; A RUNTIME trip count `n`, so the Lever-B force-unroll pre-pass (constant trip
; counts only) cannot turn the loop into straight-line code first.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: loop-carried tainted value crosses iterations

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i8 @cq_theta_ui8(i8, double)
declare i8 @cq_measure_ui8(i8)

define i8 @narrow(i32 %n) {
entry:
  %q = call i8 @cq_theta_ui8(i8 0, double 1.000000e+00)
  br label %loop

loop:
  %i = phi i32 [ 0, %entry ], [ %inext, %loop ]
  %c = phi i8 [ 0, %entry ], [ %cn, %loop ]
  %cn = add i8 %c, %q
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %inext, %n
  br i1 %done, label %exit, label %loop, !llvm.loop !0

exit:
  %m = call i8 @cq_measure_ui8(i8 %cn)
  ret i8 %m
}

!0 = distinct !{!0, !1}
!1 = !{!"llvm.loop.unroll.disable"}
