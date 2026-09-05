; control_inplace_ry_reject_inloop_invariant_cond_hoisted.ll — DECLINE (PRD §13.2
; row W): the customer's SIMPLEST C spelling of the in-loop Ry arm, refused for a
; reason that is neither R7 nor P1.
;
;     for (i = 0; i < 2; ++i) { if (q == 5) r = cq_theta(r, 0.9); }
;
; With NO gate on `q` in the body, `q` is loop-INVARIANT, so `clang -O1` LICM-hoists
; the compare `%3 = icmp eq i32 %1, 5` into the ENTRY block while the region's
; `Pred` is the loop header. `condWireDisposition`'s P4 precondition
; (`Cond->getParent() != R.Pred` — "unbounded gap across blocks") then returns
; `DeclineNow` BEFORE the compare-to-branch window scan and before any rotation
; clause runs. **The arm's own Ry plays no part in this decline at all.**
;
; THE BODY BELOW IS VERBATIM `clang -O1` OUTPUT, not a hand transcription, because
; the whole row is about what the optimizer does to the source.
;
; IT IS AN OVER-DECLINE AND IT IS PINNED DELIBERATELY. The only thing between the
; hoisted compare and the branch is the arm's own `cq_theta` on `r`, and R4 has
; already proved that rail disjoint from every condition rail — so the flag the
; mint reads IS the flag the source describes and the `_unc` strip returns it to
; |0>. What is missing is a clause that can SAY so. Both P4 and P5 are position-only
; and wire-blind BY DESIGN, and widening either is a sibling-spelling change shared
; by four callers (this path, the 4.4 select's gate 2c, 2b's S6, and
; `RegionTreeDetect`'s nest) — bd [[sibling-predicate-spelling-is-the-hole]] is
; precisely about one of four being spelled differently from the rest. Increment 3
; does not touch it; follow-on `drbq.12` owns it. This fixture is what makes the
; day it moves a DELIBERATE move.
;
; 16 cells of `tools/loop_twin_matrix.py` are this family, and the identical
; over-decline exists for the shipped Rz stem today — it is a pre-existing
; capability gap, not something Increment 3 introduces.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}condition predates a non-diagonal gate under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled
; 3qlq: migrated from register cq_phi (dead declare erased)

declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)

define i32 @slice() {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %2 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 2.500000e-01) #2
  %3 = icmp eq i32 %1, 5
  br label %8

4:                                                ; preds = %13
  %5 = tail call i32 @cq_measure_si32(i32 noundef %1) #2
  %6 = tail call i32 @cq_measure_si32(i32 noundef %14) #2
  %7 = add nsw i32 %6, %5
  ret i32 %7

8:                                                ; preds = %0, %13
  %9 = phi i32 [ 0, %0 ], [ %15, %13 ]
  %10 = phi i32 [ %2, %0 ], [ %14, %13 ]
  br i1 %3, label %11, label %13

11:                                               ; preds = %8
  %12 = tail call i32 @cq_theta_si32(i32 noundef %10, double noundef 9.000000e-01) #2
  br label %13

13:                                               ; preds = %8, %11
  %14 = phi i32 [ %12, %11 ], [ %10, %8 ]
  %15 = add nuw nsw i32 %9, 1
  %16 = icmp eq i32 %9, 0
  br i1 %16, label %8, label %4, !llvm.loop !6
}

!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
