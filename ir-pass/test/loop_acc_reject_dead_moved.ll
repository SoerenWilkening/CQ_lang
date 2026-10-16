; loop_acc_reject_dead_moved.ll — DECLINE (bd test_C_libtooling-01po.19.18): the
; DEAD-ACCUMULATOR POSTCONDITION (`declineDeadAccumulatorMoves`,
; LoopAccumulatorDead.cpp).
;
; SOURCE (clang -O1, verbatim below):
;   int main(void) {
;       int a = 0;
;       cq_theta(&a, 1.0);
;       int c = 0;
;       for (int i = 0; i < 3; i++) {
;           if (c == 1) cq_phi(0.5);
;           c += a;
;       }
;       cq_theta(&a, 0.7);
;       printf("%d\n", cq_measure(a));
;       return 0;
;   }
;
; `c` is the seeded accumulator (one register, `cqrt_add_i32(a, c)` per trip) and
; is never read after the loop, so after its last trip it is a DEAD RECORD of
; `a`; `cq_theta(&a, .7)` then moves `a` non-diagonally. A dead record standing at
; that gate dephases `a` (dead-record-live-across-move-ruling; owner ruling
; r2j3.7): MEASURED with the postcondition removed, the module lowered
; verify-clean and the trace replays to P(a=1) = 0.293377 where the program's
; circuit gives 0.531 (|cos .5 sin .35 + e^{i·.5} sin .5 cos .35|²). The
; register cannot be reversed in the rolled form yet (the post-loop reverse loop,
; bd 8h7d.20), so the module fails loudly at the gate.
; RETIREMENT TRIGGER: 8h7d.20's reverse loop uncomputes `c` after the loop and
; this becomes an accept with a trace check.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: dead loop accumulator records a register moved after its last read

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [4 x i8] c"%d\0A\00", align 1

define noundef i32 @main() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 1.000000e+00) #3
  br label %6

2:                                                ; preds = %11
  %3 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 0x3FE6666666666666) #3
  %4 = tail call i32 @cq_measure_si32(i32 noundef %3) #4
  %5 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %4)
  ret i32 0

6:                                                ; preds = %0, %11
  %7 = phi i32 [ 0, %0 ], [ %13, %11 ]
  %8 = phi i32 [ 0, %0 ], [ %12, %11 ]
  %9 = icmp eq i32 %8, 1
  br i1 %9, label %10, label %11

10:                                               ; preds = %6
  tail call void @cq_phi(double noundef 5.000000e-01) #4
  br label %11

11:                                               ; preds = %10, %6
  %12 = add nsw i32 %8, %1
  %13 = add nuw nsw i32 %7, 1
  %14 = icmp eq i32 %13, 3
  br i1 %14, label %2, label %6, !llvm.loop !0
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1
declare void @cq_phi(double noundef) local_unnamed_addr #1
declare noundef i32 @printf(ptr nocapture noundef readonly, ...) local_unnamed_addr #2
declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable }
attributes #1 = { "no-trapping-math"="true" }
attributes #2 = { nofree nounwind }
attributes #3 = { nomerge nounwind }
attributes #4 = { nounwind }

!0 = distinct !{!0, !1, !2}
!1 = !{!"llvm.loop.mustprogress"}
!2 = !{!"llvm.loop.unroll.disable"}
