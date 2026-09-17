; loop_pairing_accept_arm_minted_measure_owned_control.ll — ACCEPT, AND IT
; DISCHARGES. THE GREEN HALF and the ONE-TOKEN ISOLATING CONTROL for
; `loop_leak_dephase_reject_arm_minted_interior_rail.ll` (bd
; `test_C_libtooling-6n1s`, finding F-1 of the 2026-09-18 Rule-13 round).
;
; ONE TOKEN DIFFERENT from the RED file — `& 2` is deleted from the arm:
;
;     if (k < lim) { int e = d + 7; s += cq_measure(e); }     /* not `e & 2` */
;
; so the arm's template rail becomes **MEASURE-OWNED** instead of **INTERIOR**.
;
; ⚠ **WHAT IT PROVES, and it is the half a reader is most likely to get wrong.**
; The RED file's defect is NOT the second basic block, NOT the fan-out on `d`, NOT
; the post-loop interference and NOT the marking — this file has ALL FOUR and
; discharges correctly. The discriminant is exactly *"the ARM mints an INTERIOR
; rail"*: here the arm's `cq_template_add_i32_hl(%h_op, 7)` is consumed by a
; `cqrt_measure` and nothing else, so it is never an OWNED candidate, the component
; is `{%h_op}` alone, and `planInteriorComponent` §4's per-gate
; `DT.dominates(G, At)` has only the header's `ashr` to prove — which it does.
;
; ⚠ NOTE WHERE THE DISCHARGE LANDS AND DO NOT "TIDY" IT: the `_unc` + `free` sit in
; the JOIN block `%11`, NOT in the mint's block `%4`. That is the bd `6n1s`
; use-side relaxation working — the arm's read of `%h_op` does not DOMINATE the
; join and does not have to, because what the discharge owes is that no use runs
; between it and the next execution of the mint. `%h_op` is written exactly twice,
; by the forward gate and by its own adjoint, with `%h` unchanged between them, so
; it is `|0⟩` on every path at the free (the arm that did not run wrote nothing)
; and `cqrt_free` collapses nothing (Rule 6). Multiplicity **1 : 1 per trip**: the
; join is control-equivalent to the mint's block.
;
; ⚠ AND IT IS THE FILE THAT WOULD GO RED IF THE F-1 POSTCONDITION OVER-FIRED.
; `declineUndischargedMarkedBodyRails` must NOT refuse this module; it is the
; nearest accepting neighbour of the one it does refuse.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=COUNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=UCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RYCNT < %t.cqd0.ll
;
; The rail is minted in the header, read in the header AND in the arm, and
; discharged in the JOIN — `CHECK-NEXT` so nothing may be inserted between the
; adjoint and its free.
; CHECK-LABEL: define i32 @slice
; CHECK: %h_op = call i32 @cq_template_ashr_i32_hl(i32 %h, i32 %6)
; CHECK-NEXT: %h_op1 = call i32 @cq_template_and_i32_hl(i32 %h_op, i32 1)
; CHECK: %h_op2 = call i32 @cq_template_add_i32_hl(i32 %h_op, i32 7)
; CHECK-NEXT: %m4 = call i32 @cqrt_measure_i32(i32 %h_op2)
; CHECK: call void @cq_template_ashr_i32_hl_unc(i32 %h_op, i32 %h, i32 %6)
; CHECK-NEXT: call void @cqrt_free(i32 %h_op)
;
; MINT == ADJOINT, and the tail bounded (Rule 12 fixture-hygiene (a): counts in
; their OWN whole-file prefix, negatives pure).
; ⚠ THE COUNTS ARE **2**, NOT 1, AND THAT IS THE MODULE RATHER THAN THE TRIP COUNT —
; `-O1` INLINES `slice` into `main` here, so the module carries TWO copies of the
; same rolled loop (`grep -c '^define'` = 2). Per copy it is one mint and one
; adjoint. Read a change in these numbers as a change in the STREAM only after
; re-checking the `define` count — that is the trap `IMPL_T3.md` §7a records in
; the other direction.
; COUNT-COUNT-2: call i32 @cq_template_ashr_i32_hl(
; COUNT-NOT: call i32 @cq_template_ashr_i32_hl(
;
; UCNT-COUNT-2: call void @cq_template_ashr_i32_hl_unc(
; UCNT-NOT: call void @cq_template_ashr_i32_hl_unc(
;
; ONE free per copy — the rail's. An EXTRA free is a hidden measurement (Rule 6).
; FCNT-COUNT-2: call void @cqrt_free(
; FCNT-NOT: call void @cqrt_free(
;
; TWO uncontrolled rotations per copy — the source prep and the post-loop
; interference. An injected one is a different unitary.
; RYCNT-COUNT-4: call void @cqrt_ry_i32(
; RYCNT-NOT: call void @cqrt_ry_i32(

; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-18-orchestrator/trackT2/probes/g8a_arm_measured_directly_control.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-18-orchestrator/trackT2/probes/g8a_arm_measured_directly_control.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2
  br label %7

3:                                                ; preds = %19
  %4 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 9.000000e-01) #2
  %5 = tail call i32 @cq_measure_si32(i32 noundef %4) #2
  %6 = add nsw i32 %5, %20
  ret i32 %6

7:                                                ; preds = %1, %19
  %8 = phi i32 [ 0, %1 ], [ %20, %19 ]
  %9 = phi i32 [ 1, %1 ], [ %21, %19 ]
  %10 = ashr i32 %2, %9
  %11 = and i32 %10, 1
  %12 = tail call i32 @cq_measure_si32(i32 noundef %11) #2
  %13 = add nsw i32 %12, %8
  %14 = icmp slt i32 %9, %0
  br i1 %14, label %15, label %19

15:                                               ; preds = %7
  %16 = add nsw i32 %10, 7
  %17 = tail call i32 @cq_measure_si32(i32 noundef %16) #2
  %18 = add nsw i32 %17, %13
  br label %19

19:                                               ; preds = %15, %7
  %20 = phi i32 [ %18, %15 ], [ %13, %7 ]
  %21 = add nuw nsw i32 %9, 1
  %22 = icmp eq i32 %21, 5
  br i1 %22, label %3, label %7, !llvm.loop !6
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2
  br label %4

4:                                                ; preds = %16, %2
  %5 = phi i32 [ 0, %2 ], [ %17, %16 ]
  %6 = phi i32 [ 1, %2 ], [ %18, %16 ]
  %7 = ashr i32 %3, %6
  %8 = and i32 %7, 1
  %9 = tail call i32 @cq_measure_si32(i32 noundef %8) #2
  %10 = add nsw i32 %9, %5
  %11 = icmp sgt i32 %6, %0
  br i1 %11, label %16, label %12

12:                                               ; preds = %4
  %13 = add nsw i32 %7, 7
  %14 = tail call i32 @cq_measure_si32(i32 noundef %13) #2
  %15 = add nsw i32 %14, %10
  br label %16

16:                                               ; preds = %12, %4
  %17 = phi i32 [ %15, %12 ], [ %10, %4 ]
  %18 = add nuw nsw i32 %6, 1
  %19 = icmp eq i32 %18, 5
  br i1 %19, label %20, label %4, !llvm.loop !6

20:                                               ; preds = %16
  %21 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 9.000000e-01) #2
  %22 = tail call i32 @cq_measure_si32(i32 noundef %21) #2
  %23 = add nsw i32 %22, %17
  ret i32 %23
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
