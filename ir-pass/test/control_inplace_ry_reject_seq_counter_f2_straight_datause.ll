; control_inplace_ry_reject_seq_counter_f2_straight_datause.ll — DECLINE: a straight-through pin by a compare that is not a pure sibling condition.
;
; bd test_C_libtooling-dm7f.53, amended delegated ruling
; `ruling-dm7f53-p4-sibling-cond-prep-amend-straight-through-2026-10-15`: F2's
; sibling-condition exclusion (`siblingConditionCompareOnWire`) also covers a
; sibling compare that F2's own LVI edge pin forces to the seed on region 1's
; STRAIGHT-THROUGH (not-taken) edge. The -O1 rival `else t = V` is a
; controlled permutation whose control predicate (¬C ∧ V ≠ seed) is
; unsatisfiable on every basis state: the identity operator. Forcedness IS the
; F2 pin (one spelling, R12); each covered collider is tagged `!cq.f2.sibling`
; and its structure re-asked after the round-2 fixpoint
; (`declineRound2QuantumPrepSeeds`, both entry points).
;
;   if (x < 3) Ry(t,.3); if (x < 2) Ry(t,.7); bool k = (x < 1); if (k) Ry(t,.9); … cq_measure(k)
; `x < 2` (covered) and `x < 1` are both forced false on the x >= 3 edge; `x < 1`
; is also DATA (measured), so it is not excluded — the set question keeps the
; region loud. (A compare F2 cannot pin is no collider at all, so the
; "unforced" member of the set is spelled as the not-excludable one.)
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
  %15 = icmp slt i32 %1, 1
  br i1 %15, label %16, label %20

16:
  %17 = trunc nuw i8 %14 to i1
  %18 = call i1 @cq_theta_i1(i1 %17, double 9.000000e-01)
  %19 = zext i1 %18 to i8
  br label %20

20:
  %21 = phi i8 [ %19, %16 ], [ %14, %13 ]
  %22 = call i32 @cq_measure_si32(i32 %1)
  %23 = trunc nuw i8 %21 to i1
  %24 = call i1 @cq_measure_i1(i1 %23)
  %25 = zext i1 %24 to i32
  %26 = add nsw i32 %22, %25
  %27 = call i1 @cq_measure_i1(i1 %15)
  %28 = zext i1 %27 to i32
  %29 = add nsw i32 %26, %28
  ret i32 %29
}

; CHECK: cq controlled lowering: state prep seed is proven equal to the condition register under quantum control
