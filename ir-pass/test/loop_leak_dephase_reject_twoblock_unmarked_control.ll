; loop_leak_dephase_reject_twoblock_unmarked_control.ll — DECLINE. THE SECOND
; ISOLATING CONTROL for bd `test_C_libtooling-6n1s` (2026-09-18): the SAME
; two-block body as `loop_pairing_accept_twoblock_body_straddle.ll`, plus one
; iteration-local temp that ESCAPES the loop, so `railLocalQualifies` refuses the
; marking and `declineDephasingUnmarkedLoopRails` conjunct (1) cannot suppress.
;
;     for (int k = 1; k <= 4; ++k) {
;         int d = (y >> k);
;         last = d & 4;                      /* escapes the loop */
;         s += cq_measure(d & 1);
;         if (k < lim) s += cq_measure(d & 2);
;     }
;     cq_theta(&y, 0.9);
;     return s + cq_measure(last) + cq_measure(y);
;
; WHAT IT PROVES: that the MARKING is the door. It DECLINES on the session ORACLE
; `9bd01598d574b344` and on the subject, with the same string, while its
; unmarked-temp-free twin flipped from a silent leak to a per-trip discharge. A
; reader who suspects the 6n1s fix of widening the fence's own population can
; check that suspicion here: this file's verdict is UNMOVED by the fix.
;
; ⚠ IT IS ALSO THE CONTROL FOR THE **FENCE** HALF OF THAT INCREMENT.
; `declineDephasingUnmarkedLoopRails` conjunct (1) now carries a second conjunct
; (`markedBodyRailsHaveInBodyDischargePoint`), and this file reaches the fence
; through conjunct (1)'s FIRST half — the body is not marked at all — so it pins
; that the new conjunct did not disturb the pre-existing route.
;
; ⚠ RULE-12 HYGIENE (b): a `DS_Error` decline writes ZERO bytes to stdout, so the
; property below is pinned by the `not` inversion on the RUN line and by the
; message match, NOT by any IR-text check. Do not add `CHECK-NOT`s over lowered
; IR here and read them as coverage.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
;
; CHECK: cq loop lowering: rolled body leaks a rail entangled with a rotated register

; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-18-orchestrator/trackT2/probes/t5k_twoblock_unmarked_control.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-18-orchestrator/trackT2/probes/t5k_twoblock_unmarked_control.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2
  br label %10

3:                                                ; preds = %22
  %4 = and i32 %13, 4
  %5 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 9.000000e-01) #2
  %6 = tail call i32 @cq_measure_si32(i32 noundef %4) #2
  %7 = add nsw i32 %6, %23
  %8 = tail call i32 @cq_measure_si32(i32 noundef %5) #2
  %9 = add nsw i32 %7, %8
  ret i32 %9

10:                                               ; preds = %1, %22
  %11 = phi i32 [ 1, %1 ], [ %24, %22 ]
  %12 = phi i32 [ 0, %1 ], [ %23, %22 ]
  %13 = ashr i32 %2, %11
  %14 = and i32 %13, 1
  %15 = tail call i32 @cq_measure_si32(i32 noundef %14) #2
  %16 = add nsw i32 %15, %12
  %17 = icmp slt i32 %11, %0
  br i1 %17, label %18, label %22

18:                                               ; preds = %10
  %19 = and i32 %13, 2
  %20 = tail call i32 @cq_measure_si32(i32 noundef %19) #2
  %21 = add nsw i32 %20, %16
  br label %22

22:                                               ; preds = %18, %10
  %23 = phi i32 [ %21, %18 ], [ %16, %10 ]
  %24 = add nuw nsw i32 %11, 1
  %25 = icmp eq i32 %24, 5
  br i1 %25, label %3, label %10, !llvm.loop !6
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = add nsw i32 %0, 1
  %4 = tail call i32 @slice(i32 noundef %3)
  ret i32 %4
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
