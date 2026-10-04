; control_phase_kickback_rail_inloop_iterlocal_measure_after.ll — ACCEPT, and a
; DECLINE → ACCEPT MOVER ON `main` 0c7380c (Track A.1, Rule-13 round-1 finding
; F-A1-2). Verbatim `clang -O1` from `review_a1_r1_probes/b1.c`:
;
;     for (int i = 0; i < 3; ++i) {
;         _Bool b = (_Bool)0; cq_theta(&b, 0.5);
;         if (b) cq_phi(0.3);                 /* the bare-rail kickback, 1b */
;         acc += cq_measure(b) + ext(i);
;     }
;
; MEASURED: `main` 0c7380c DECLINES it `condition measured before the control
; route`; this branch ACCEPTS. That is the ONE direction Track A.1 moves that is
; not a decline, it is on the RAIL ladder (not the compare path this increment
; is about), and it reaches the rail ladder because rung (ii)'s helper
; `railMeasuredBeforeReadPoint` is SHARED with 1b/1b-B.1 — `classifyPhaseKickback`
; step 5b, `classifySelectRegion`'s rail loop and `reverifyRailCondReads` all
; call it. The corpus diff could not see it: no fixture had the shape. This file
; and its select twin `control_swap_select_rail_inloop_iterlocal_measure_after.ll`
; are that gap closed.

; ⚠ WHY THE ACCEPT IS RIGHT, CHECKED PHYSICALLY AND NOT ASSUMED. The register is
; ITERATION-LOCAL: `cqrt_alloc_i1` is emitted INSIDE the loop body (asserted
; below), so every trip mints a FRESH physical register, and the body's
; `cq_measure` collapses the register THIS trip minted — never the one the NEXT
; trip's control read names. `isPotentiallyReachable(M, ReadPoint)` alone answers
; "can the read follow the measure?" with TRUE around any back edge, which is the
; WRONG question inside a loop; the right one is "can it follow it ON THE SAME
; REGISTER?", and the barrier is what asks it. Without the barrier five shipped
; accepts move (`control_swap_inloop_diamond_iterlocal.ll`, `…_seq`, and the
; three `…_reject_inloop_{irreducible,multilatch,second_cycle}` declines, which
; would keep declining on the WRONG rung — a DIAGDIFF).
;
; THE BARRIER IS THE WIRE ORIGIN AND ONLY WHEN IT IS A SOURCE THETA
; (`railMeasuredBeforeReadPoint`, ArmClassify.cpp): a source theta lowers to a
; fresh `cqrt_alloc_<W>` + `cqrt_ry_<W>` on EVERY execution, so a measurement
; followed by a re-execution of the origin on EVERY path back to the read point
; collapsed a register this read can no longer name. A CHAINED theta refreshes
; nothing (an in-place Ry) and a non-theta origin is refused too; a MISSING
; barrier DECLINES. Its round-2 blind spot — a `cq_theta` that is a SOURCE at
; round-1 taint and CHAINED at final taint — is closed by the UNGATED rung (ii)
; in `reverifyCmpCondReads` (reviewer probe `o7a`, ACCEPT on `main` and DECLINE
; here).

; The compare-path twin of the same shape is
; `control_swap_select_cmp_inloop_iterlocal_measure_after.ll`.

; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=ACNT %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=MCNT %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=RYCNT %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=FCNT %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=NOROUTE %s < %t.cqd0.ll

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  br label %2

1:                                                ; preds = %7
  ret i32 %12

2:                                                ; preds = %0, %7
  %3 = phi i32 [ 0, %0 ], [ %12, %7 ]
  %4 = phi i32 [ 0, %0 ], [ %13, %7 ]
  %5 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2
  br i1 %5, label %6, label %7

6:                                                ; preds = %2
  tail call void @cq_phi(double noundef 3.000000e-01) #2
  br label %7

7:                                                ; preds = %6, %2
  %8 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %5) #2
  %9 = zext i1 %8 to i32
  %10 = tail call i32 @ext(i32 noundef %4) #2
  %11 = add i32 %3, %9
  %12 = add i32 %11, %10
  %13 = add nuw nsw i32 %4, 1
  %14 = icmp eq i32 %13, 3
  br i1 %14, label %1, label %2, !llvm.loop !6
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

declare i32 @ext(i32 noundef) local_unnamed_addr #1

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

; THE MINT IS IN THE BODY — the block that the latch branches back to — which is
; the whole ground of the accept. `CHECK-LABEL` pins the loop block, and the
; alloc follows it.
; CHECK-LABEL: 2:
; CHECK:      %h = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %h, double 5.000000e-01)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %h, double 3.000000e-01), !cq.branchphase
; CHECK-NEXT: %m = call i1 @cqrt_measure_i1(i32 %h)

; ONE mint, ONE rotation, ONE kickback, ONE measurement PER ACTIVATION — the
; loop is ROLLED, so these are whole-file counts of one iteration's text.
; ACNT-COUNT-1:  call i32 @cqrt_alloc_i1(
; ACNT-NOT:      call i32 @cqrt_alloc
; MCNT-COUNT-1:  call i1 @cqrt_measure_i1(
; MCNT-NOT:      call i1 @cqrt_measure
; RYCNT-COUNT-1: call void @cqrt_ry_i1(
; RYCNT-NOT:     call void @cqrt_ry
; The rail is the flag: nothing is minted for it and nothing is freed (a dead
; register left ALLOCATED is Rule 6's safe direction — `Ry(-t)P(f)Ry(t)|0> != |0>`).
; FCNT-NOT:      call void @cqrt_free(
; NOROUTE-NOT:   @cqrt_cswap
; NOROUTE-NOT:   call void @cqrt_x(
; NOROUTE-NOT:   call i32 @cq_theta
; NOROUTE-NOT:   call void @cq_phi
