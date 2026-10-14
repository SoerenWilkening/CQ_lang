; control_inplace_ry_reject_seq_counter_f2_straight_offwire.ll — DECLINE: a straight-through pin through an OFF-wire register.
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
;   if (x != 0) Ry(t,.3); if ((x >> 1) == 3) Ry(t,.7);
; On the straight-through edge (x == 0) `(and x, -2) == 6` is pinned to the
; seed through the `and`, which is not a CondWire member: loud.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare i32 @cq_theta_si32(i32, double)
declare i1 @cq_theta_i1(i1, double)
declare i32 @cq_measure_si32(i32)
declare i1 @cq_measure_i1(i1)

define i32 @example() {
  %1 = call i32 @cq_theta_si32(i32 0, double 1.000000e+00)
  %2 = icmp eq i32 %1, 0
  br i1 %2, label %6, label %3

3:
  %4 = call i1 @cq_theta_i1(i1 false, double 3.000000e-01)
  %5 = zext i1 %4 to i8
  br label %6

6:
  %7 = phi i8 [ %5, %3 ], [ 0, %0 ]
  %8 = and i32 %1, -2
  %9 = icmp eq i32 %8, 6
  br i1 %9, label %10, label %14

10:
  %11 = trunc nuw i8 %7 to i1
  %12 = call i1 @cq_theta_i1(i1 %11, double 0x3FE6666666666666)
  %13 = zext i1 %12 to i8
  br label %14

14:
  %15 = phi i8 [ %13, %10 ], [ %7, %6 ]
  %16 = call i32 @cq_measure_si32(i32 %1)
  %17 = trunc nuw i8 %15 to i1
  %18 = call i1 @cq_measure_i1(i1 %17)
  %19 = zext i1 %18 to i32
  %20 = add nsw i32 %16, %19
  ret i32 %20
}

; CHECK: cq controlled lowering: state prep seed is proven equal to the condition register under quantum control
