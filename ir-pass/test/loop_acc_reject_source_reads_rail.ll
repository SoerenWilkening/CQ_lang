; loop_acc_reject_source_reads_rail.ll — DECLINE (bd test_C_libtooling-01po.19.18):
; the SEEDED ACCUMULATOR's aliasing refusal (LoopAccumulator.h (A3),
; `accSourceReadsRail`).
;     int c = 1; for (i < n) c = c + (c & q);
; The step's SOURCE `c & q` reads the register it would be added into: the
; aliased pair `x += f(x)` that both references refuse (BennettVM.jl 23d28e6
; src/ir/arithmetic_assignment.jl:79, "forbidden by use-discipline"; Bennett.jl
; 824458d1 src/adder.jl:103, `lower_add_cuccaro!` refuses a ∩ b). An in-place
; `cqrt_add_i32(src, c)` would read `c`'s rail through `src` while writing it —
; no reversible in-place form. Not lowered yet: the X1 decline stands (loudly),
; and `seededAccumulatorPhi` returns nullopt so nothing is minted.
; RETIREMENT TRIGGER: a scratch-register lowering (copy, add, uncompute) of a
; self-dependent source makes this an accept.
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

define i32 @alias(i32 %n) {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 1.000000e+00)
  br label %loop

loop:
  %i = phi i32 [ 0, %entry ], [ %inext, %loop ]
  %c = phi i32 [ 1, %entry ], [ %cn, %loop ]
  %t = and i32 %c, %q
  %cn = add nuw nsw i32 %t, %c
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %inext, %n
  br i1 %done, label %exit, label %loop, !llvm.loop !0

exit:
  %m = call i32 @cq_measure_si32(i32 %cn)
  ret i32 %m
}

!0 = distinct !{!0, !1}
!1 = !{!"llvm.loop.unroll.disable"}
