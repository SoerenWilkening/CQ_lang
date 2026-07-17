; lowering_unroll_reject_dynamic_trip.ll — LEAVE→DECLINE (3c6m.55 Inc 2 Lever B,
; ticket lf8s; the U6 fence probe): the EXACT body of the accepted
; `lowering_unroll_const_trip.ll` Horner loop with ONE change — the countdown
; starts from the ARGUMENT `%n` instead of the constant 2, so SCEV cannot fold
; the backedge-taken count to a constant. The force-unroll pre-pass must SKIP
; (accept-only discipline: off-fence loops are byte-untouched) and the loop
; keeps its existing owner: `tryCaseA`'s X1 cross-iteration decline, pinned
; CHARACTER-FOR-CHARACTER (Rule 12 — the discriminating pair for the fence is
; this fixture against the positive, differing only in the trip bound).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: loop-carried tainted value crosses iterations

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@C = internal constant [3 x double] [double 1.000000e+00, double 2.000000e+00, double 3.000000e+00], align 8

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare double @llvm.fmuladd.f64(double, double, double)

define double @horner(double %seed, double %mul, i32 %n) {
entry:
  %acc0 = call double @cq_theta_f64(double %seed, double 5.000000e-01)
  %x = call double @cq_theta_f64(double %mul, double 2.500000e-01)
  br label %loop

loop:                                             ; preds = %entry, %loop
  %i = phi i32 [ %n, %entry ], [ %dec, %loop ]
  %acc = phi double [ %acc0, %entry ], [ %fma, %loop ]
  %p = phi ptr [ @C, %entry ], [ %gep, %loop ]
  %gep = getelementptr inbounds i8, ptr %p, i64 8
  %c = load double, ptr %gep, align 8
  %fma = call double @llvm.fmuladd.f64(double %acc, double %x, double %c)
  %dec = add nsw i32 %i, -1
  %done = icmp eq i32 %dec, 0
  br i1 %done, label %exit, label %loop, !llvm.loop !0

exit:                                             ; preds = %loop
  %m = call double @cq_measure_f64(double %fma)
  ret double %m
}

!0 = distinct !{!0, !1}
!1 = !{!"llvm.loop.unroll.disable"}
