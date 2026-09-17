; loop_pairing_accept_oneblock_body_control.ll — THE ISOLATING CONTROL for
; `loop_pairing_accept_twoblock_body_straddle.ll` (bd `test_C_libtooling-6n1s`,
; 2026-09-18). ONE OPERAND DIFFERENT: the `if (k < lim)` guard is deleted, so the
; marked body is a SINGLE basic block.
;
;     for (int k = 1; k <= 4; ++k) {
;         int d = (y >> k);
;         s += cq_measure(d & 1);
;         s += cq_measure(d & 2);      /* NOT guarded — one body block */
;     }
;     y = cq_theta(y, 0.9);
;
; WHAT IT PROVES, and it is the half a reader is most likely to get wrong: the
; 6n1s defect was **the second block**, not the rail, not the fan-out and not the
; post-loop interference — all four of which this file also has. This module
; ACCEPTS and DISCHARGES on BOTH the session ORACLE `9bd01598d574b344` AND the
; subject, byte-identically, and it is therefore the file that would go red if
; `useCompleteBeforeDischarge`'s new second arm were ever spelled so that it
; changed the SINGLE-block placement instead of adding to it.
;
; ⚠ NOTE THE DISCHARGE POSITION AND DO NOT "TIDY" IT. The `_unc` + `free` land
; BETWEEN `cq_template_and_i32_hl(%h_op, 2)` and that rail's own
; `cqrt_measure_i32` — i.e. after the last READ of `%h_op` and before an
; instruction that does not touch it. That is `dagInsertPoint`'s "latest anchor in
; the common block", and it is where stage 2b can see it: this file measures
; `2 cqrt_free site(s): 2 verified, 0 unproven` where the two-block twin measures
; `0 verified, 0 violation(s), 2 unproven` — the checker's stream model, not a
; difference in the circuit.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=COUNT < %t.cqd0.ll
;
; CHECK-LABEL: define i32 @slice
; CHECK: %h_op = call i32 @cq_template_ashr_i32_hl(i32 %h, i32 %5)
; CHECK: %h_op2 = call i32 @cq_template_and_i32_hl(i32 %h_op, i32 2)
; CHECK-NEXT: call void @cq_template_ashr_i32_hl_unc(i32 %h_op, i32 %h, i32 %5)
; CHECK-NEXT: call void @cqrt_free(i32 %h_op)
; CHECK: call void @cqrt_ry_i32(i32 %h, double 9.000000e-01)
;
; COUNT-COUNT-1: call i32 @cq_template_ashr_i32_hl(
; COUNT-COUNT-1: call void @cq_template_ashr_i32_hl_unc(
; COUNT-COUNT-1: call void @cqrt_free(

; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-18-orchestrator/trackT2/probes/t5i_straddle_nobreak_rot.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-18-orchestrator/trackT2/probes/t5i_straddle_nobreak_rot.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2
  br label %7

3:                                                ; preds = %7
  %4 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 9.000000e-01) #2
  %5 = tail call i32 @cq_measure_si32(i32 noundef %4) #2
  %6 = add nsw i32 %5, %16
  ret i32 %6

7:                                                ; preds = %1, %7
  %8 = phi i32 [ 1, %1 ], [ %17, %7 ]
  %9 = phi i32 [ 0, %1 ], [ %16, %7 ]
  %10 = ashr i32 %2, %8
  %11 = and i32 %10, 1
  %12 = tail call i32 @cq_measure_si32(i32 noundef %11) #2
  %13 = add nsw i32 %12, %9
  %14 = and i32 %10, 2
  %15 = tail call i32 @cq_measure_si32(i32 noundef %14) #2
  %16 = add nsw i32 %13, %15
  %17 = add nuw nsw i32 %8, 1
  %18 = icmp eq i32 %17, 5
  br i1 %18, label %3, label %7, !llvm.loop !6
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2
  br label %4

4:                                                ; preds = %4, %2
  %5 = phi i32 [ 1, %2 ], [ %14, %4 ]
  %6 = phi i32 [ 0, %2 ], [ %13, %4 ]
  %7 = ashr i32 %3, %5
  %8 = and i32 %7, 1
  %9 = tail call i32 @cq_measure_si32(i32 noundef %8) #2
  %10 = add nsw i32 %9, %6
  %11 = and i32 %7, 2
  %12 = tail call i32 @cq_measure_si32(i32 noundef %11) #2
  %13 = add nsw i32 %10, %12
  %14 = add nuw nsw i32 %5, 1
  %15 = icmp eq i32 %14, 5
  br i1 %15, label %16, label %4, !llvm.loop !6

16:                                               ; preds = %4
  %17 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 9.000000e-01) #2
  %18 = tail call i32 @cq_measure_si32(i32 noundef %17) #2
  %19 = add nsw i32 %18, %13
  ret i32 %19
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
