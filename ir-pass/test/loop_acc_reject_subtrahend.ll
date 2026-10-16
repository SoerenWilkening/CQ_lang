; loop_acc_reject_subtrahend.ll — DECLINE (bd test_C_libtooling-01po.19.18):
; the SEEDED ACCUMULATOR's direction refusal (LoopAccumulator.h (A3)).
;     int c = 0; for (i < n) c = q - c;     // -O1: sub nsw i32 %q, %c
; `sub` is not commutative: only the MINUEND can be the register (`c -= q` is
; `cqrt_sub_i32(q, c)`); `c = q - c` overwrites the SUBTRAHEND, which no
; `cqrt_{add,sub,xor}` form expresses (it is negate-then-add on the register).
; The walk tries operand 0 only for `sub`, operand 0 is `q`, not the rail, so
; nothing is minted and the X1 decline stands, loudly.
; RETIREMENT TRIGGER: an in-place negate (`cqrt_neg_<W>`) composes it.
;
; A RUNTIME trip count `n`, so the Lever-B force-unroll pre-pass (constant trip
; counts only) cannot turn the loop into straight-line code first.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: loop-carried tainted value crosses iterations

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @subtrahend(i32 %n) {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 1.000000e+00)
  br label %loop

loop:
  %i = phi i32 [ 0, %entry ], [ %inext, %loop ]
  %c = phi i32 [ 0, %entry ], [ %cn, %loop ]
  %cn = sub nsw i32 %q, %c
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %inext, %n
  br i1 %done, label %exit, label %loop, !llvm.loop !0

exit:
  %m = call i32 @cq_measure_si32(i32 %cn)
  ret i32 %m
}

!0 = distinct !{!0, !1}
!1 = !{!"llvm.loop.unroll.disable"}
