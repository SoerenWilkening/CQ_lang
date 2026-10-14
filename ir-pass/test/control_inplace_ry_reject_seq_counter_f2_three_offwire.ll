; control_inplace_ry_reject_seq_counter_f2_three_offwire.ll — DECLINE: three siblings, one off-wire collider.
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
;   if (x == 0) Ry(t,.3); if (x > 5) Ry(t,.7); if ((x >> 1) == 3) Ry(t,.9);
; `x > 5` is excluded (forced, on-wire) but `(and x,-2) == 6` is pinned to the
; seed through an OFF-wire `and`: the set question — one unexcluded collider
; keeps the region loud.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare i32 @cq_theta_si32(i32, double)
declare i1 @cq_theta_i1(i1, double)
declare i32 @cq_measure_si32(i32)
declare i1 @cq_measure_i1(i1)

define i32 @example() {
  %1 = call i32 @cq_theta_si32(i32 0, double 1.000000e+00)
  %2 = icmp eq i32 %1, 0
  br i1 %2, label %3, label %6

3:
  %4 = call i1 @cq_theta_i1(i1 false, double 3.000000e-01)
  %5 = zext i1 %4 to i8
  br label %6

6:
  %7 = phi i8 [ %5, %3 ], [ 0, %0 ]
  %8 = icmp sgt i32 %1, 5
  br i1 %8, label %9, label %13

9:
  %10 = trunc nuw i8 %7 to i1
  %11 = call i1 @cq_theta_i1(i1 %10, double 0x3FE6666666666666)
  %12 = zext i1 %11 to i8
  br label %13

13:
  %14 = phi i8 [ %12, %9 ], [ %7, %6 ]
  %15 = and i32 %1, -2
  %16 = icmp eq i32 %15, 6
  br i1 %16, label %17, label %21

17:
  %18 = trunc nuw i8 %14 to i1
  %19 = call i1 @cq_theta_i1(i1 %18, double 9.000000e-01)
  %20 = zext i1 %19 to i8
  br label %21

21:
  %22 = phi i8 [ %20, %17 ], [ %14, %13 ]
  %23 = call i32 @cq_measure_si32(i32 %1)
  %24 = trunc nuw i8 %22 to i1
  %25 = call i1 @cq_measure_i1(i1 %24)
  %26 = zext i1 %25 to i32
  %27 = add nsw i32 %23, %26
  ret i32 %27
}

; CHECK: cq controlled lowering: state prep seed is proven equal to the condition register under quantum control
