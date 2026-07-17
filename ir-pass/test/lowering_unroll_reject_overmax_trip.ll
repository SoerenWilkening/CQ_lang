; lowering_unroll_reject_overmax_trip.ll — LEAVE→DECLINE (3c6m.55 Inc 2 Lever B,
; ticket lf8s; the U6 max-trip fence probe): the accepted Horner shape with a
; PROVEN constant trip of 100 — exact, but ABOVE kMaxUnrollTrip (8). The
; force-unroll pre-pass must SKIP (bounded code growth is part of the fence
; contract) and the loop keeps its existing X1 cross-iteration decline, pinned
; CHARACTER-FOR-CHARACTER. Discriminates the max-trip bound from the
; constant-trip proof itself (`lowering_unroll_reject_dynamic_trip.ll`).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: loop-carried tainted value crosses iterations

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare double @llvm.fmuladd.f64(double, double, double)

define double @horner(double %seed, double %mul) {
entry:
  %acc0 = call double @cq_theta_f64(double %seed, double 5.000000e-01)
  %x = call double @cq_theta_f64(double %mul, double 2.500000e-01)
  br label %loop

loop:                                             ; preds = %entry, %loop
  %i = phi i32 [ 100, %entry ], [ %dec, %loop ]
  %acc = phi double [ %acc0, %entry ], [ %fma, %loop ]
  %fma = call double @llvm.fmuladd.f64(double %acc, double %x, double 7.000000e+00)
  %dec = add nsw i32 %i, -1
  %done = icmp eq i32 %dec, 0
  br i1 %done, label %exit, label %loop, !llvm.loop !0

exit:                                             ; preds = %loop
  %m = call double @cq_measure_f64(double %fma)
  ret double %m
}

!0 = distinct !{!0, !1}
!1 = !{!"llvm.loop.unroll.disable"}
