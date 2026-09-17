; loop_leak_dephase_reject_arm_minted_unmarked_control.ll — DECLINE. THE SECOND
; ISOLATING CONTROL for `loop_leak_dephase_reject_arm_minted_interior_rail.ll`
; (bd `test_C_libtooling-6n1s` F-1, 2026-09-18): the SAME arm-minted interior rail,
; plus one iteration-local temp that ESCAPES the loop, so `railLocalQualifies`
; refuses the marking and conjunct (1) never suppresses in the first place.
;
; ⚠ **WHAT IT PROVES: the MARKING is the door, by measurement.** This module
; DECLINES on every binary in the chain — the pre-group `0e280fc6`, the session
; ORACLE `9bd01598`, the bd-`6n1s`+P1+P2 subject `7c1163ad`, the P0+P3 branch
; `e951d5d1` and the F-1 fix — always with the string below, and always through
; conjunct (1)'s FIRST half (the body is not marked at all). Its twin, one escaping
; temp away, ACCEPTED at exit 0 on three of those five with four coherent
; which-path records live at a non-diagonal gate. **A reader who suspects the F-1
; fix of widening the fence's own population can check that suspicion here: this
; file's verdict is UNMOVED by it.**
;
; ⚠ IT ALSO PINS THAT THE FIX DID NOT MOVE THE ROUTE. The F-1 change makes
; conjunct (1) RECORD rather than suppress, and this file never reaches the record
; — it reaches the decline through the pre-existing path, so the two routes stay
; distinguishable and a future edit that collapses them will show up here.
;
; ⚠ RULE-12 HYGIENE (b): a `DS_Error` decline writes ZERO bytes to stdout, so the
; property is pinned by the `not` inversion on the RUN line plus the message match,
; never by an IR-text `CHECK-NOT`.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
;
; CHECK: cq loop lowering: rolled body leaks a rail entangled with a rotated register

; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-18-orchestrator/trackT2/probes/g8k_arm_use_derived_unmarked_control.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-18-orchestrator/trackT2/probes/g8k_arm_use_derived_unmarked_control.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2
  br label %10

3:                                                ; preds = %23
  %4 = and i32 %13, 8
  %5 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 9.000000e-01) #2
  %6 = tail call i32 @cq_measure_si32(i32 noundef %4) #2
  %7 = add nsw i32 %6, %24
  %8 = tail call i32 @cq_measure_si32(i32 noundef %5) #2
  %9 = add nsw i32 %7, %8
  ret i32 %9

10:                                               ; preds = %1, %23
  %11 = phi i32 [ 0, %1 ], [ %24, %23 ]
  %12 = phi i32 [ 1, %1 ], [ %25, %23 ]
  %13 = ashr i32 %2, %12
  %14 = and i32 %13, 1
  %15 = tail call i32 @cq_measure_si32(i32 noundef %14) #2
  %16 = add nsw i32 %15, %11
  %17 = icmp slt i32 %12, %0
  br i1 %17, label %18, label %23

18:                                               ; preds = %10
  %19 = add i32 %13, 3
  %20 = and i32 %19, 2
  %21 = tail call i32 @cq_measure_si32(i32 noundef %20) #2
  %22 = add nsw i32 %21, %16
  br label %23

23:                                               ; preds = %18, %10
  %24 = phi i32 [ %22, %18 ], [ %16, %10 ]
  %25 = add nuw nsw i32 %12, 1
  %26 = icmp eq i32 %25, 5
  br i1 %26, label %3, label %10, !llvm.loop !6
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
