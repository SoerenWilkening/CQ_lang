; control_inplace_ry_reject_seq_counter_f2_nonarm_edge.ll — DECLINE: the sibling pin is on the STRAIGHT-THROUGH edge.
;
; bd test_C_libtooling-dm7f.53, amended delegated ruling
; `ruling-dm7f53-p4-sibling-cond-prep-amend-forced-2026-10-15`: F2's fourth
; exclusion (`siblingConditionForcedOnArmEdge`) is predicate-agnostic — any
; icmp of a CondWire register against a literal, used only as branch
; conditions, that `isImpliedCondition` proves FORCED on the region's arm edge.
; The rival `t = V` then holds V's forced value on every branch the arm runs
; in: the identity on the seed. Collisions on the straight-through edge, fcmp,
; off-wire registers and data-used compares stay loud.
;
;   if (x < 3) Ry(t,.3); if (x < 2) Ry(t,.7);
; `x < 2` is forced false only on region 1's FALSE (no-arm) edge. The ruling
; covers the arm (dominating) edge only, so F2 keeps it. Physically this is a
; valid circuit (no rival folds the ARM seed); widening is an OWNER question,
; raised with the dm7f.53 report.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare i32 @cq_theta_si32(i32, double)
declare i1 @cq_theta_i1(i1, double)
declare i32 @cq_measure_si32(i32)
declare i1 @cq_measure_i1(i1)

define i32 @example() {
  %1 = call i32 @cq_theta_si32(i32 0, double 1.000000e+00)
  %2 = icmp slt i32 %1, 3
  br i1 %2, label %3, label %6

3:
  %4 = call i1 @cq_theta_i1(i1 false, double 3.000000e-01)
  %5 = zext i1 %4 to i8
  br label %6

6:
  %7 = phi i8 [ %5, %3 ], [ 0, %0 ]
  %8 = icmp slt i32 %1, 2
  br i1 %8, label %9, label %13

9:
  %10 = trunc nuw i8 %7 to i1
  %11 = call i1 @cq_theta_i1(i1 %10, double 0x3FE6666666666666)
  %12 = zext i1 %11 to i8
  br label %13

13:
  %14 = phi i8 [ %12, %9 ], [ %7, %6 ]
  %15 = call i32 @cq_measure_si32(i32 %1)
  %16 = trunc nuw i8 %14 to i1
  %17 = call i1 @cq_measure_i1(i1 %16)
  %18 = zext i1 %17 to i32
  %19 = add nsw i32 %15, %18
  ret i32 %19
}

; CHECK: cq controlled lowering: state prep seed is proven equal to the condition register under quantum control
