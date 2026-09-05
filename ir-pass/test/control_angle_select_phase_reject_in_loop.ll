; control_angle_select_phase_reject_in_loop.ll — DECLINE, and it pins an
; OVER-DECLINE OF A DECLARED §6.2 ACCEPT SHAPE (Rule-13 round-1 finding F-L5-4;
; bd test_C_libtooling-3qlq Inc 1 part A, lens L5).
;
;     for (int i = 0; i < 2; ++i) {
;         if (q == 5) cq_phi(0.9); else cq_phi(0.3);   // P2, the angle select
;         q = cq_theta(q, -0.5);                       // the diffusion
;     }
;
; `clang -O1` output verbatim: SimplifyCFG merges the two arms into ONE
; `call void @cq_phi(double %8)` on `%8 = select i1 %7, double 0.9, double 0.3`.
;
; PRD §6.2 row P6 declares "P1–P3 inside a classically-bounded loop" an ACCEPT
; shape. P2 in a loop DECLINES — measured on this module and on its FLAT twin's
; hand-unrolled spelling, so it is DECLINE-BOTH rather than a rolled/unrolled
; asymmetry — with `condition predates a non-diagonal gate under quantum
; control`. The flat form of the same region ACCEPTS
; (`control_angle_select_phase_constants.ll`); what the loop adds is the body's
; own `cq_theta` on `q` AFTER the select consumer, which the kjd1 gate-2c /
; drbq P4 window reads as a non-diagonal gate standing over the condition wire.
;
; WHY IT SHIPS AS A DECLINE RATHER THAN A WIDENING. The string comes from the
; POSITIONAL fence, not from the angle-select S7 loop prong, so the fix is a
; positional change in the Rule-13 core — the same class drbq Inc 3 solved for
; the Ry ARM with `recordLivePerActivation` (barrier = the record's own def), and
; that took its own increment and its own adversarial round. Loud and safe is the
; Prime-Directive answer for round 1; this file exists so the red-green already
; exists when P6 is completed, and so nobody reads §6.2 as a statement about the
; shipped suite. Filed as an OWNER QUESTION in
; `docs/prd/phase-04-swap-route-control/RETIRE_SWAP_ROUTE_INC1_NOTES.md` §1.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error: {{.*}}cq controlled lowering: condition predates a non-diagonal gate under quantum control
; CHECK-NOT: cqrt_rz

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @slice() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #1
  br label %4

2:                                                ; preds = %4
  %3 = tail call i32 @cq_measure_si32(i32 noundef %9) #1
  ret i32 %3

4:                                                ; preds = %0, %4
  %5 = phi i32 [ 0, %0 ], [ %10, %4 ]
  %6 = phi i32 [ %1, %0 ], [ %9, %4 ]
  %7 = icmp eq i32 %6, 5
  %8 = select i1 %7, double 9.000000e-01, double 3.000000e-01
  tail call void @cq_phi(double noundef %8) #1
  %9 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef -5.000000e-01) #1
  %10 = add nuw nsw i32 %5, 1
  %11 = icmp eq i32 %5, 0
  br i1 %11, label %4, label %2
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1
declare void @cq_phi(double noundef) local_unnamed_addr #1
declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable }
attributes #1 = { nounwind }
