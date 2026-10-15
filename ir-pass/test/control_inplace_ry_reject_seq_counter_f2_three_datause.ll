; control_inplace_ry_reject_seq_counter_f2_three_datause.ll — DECLINE: three siblings, one forced but DATA-used.
;
; bd test_C_libtooling-dm7f.53, amended delegated ruling
; `ruling-dm7f53-p4-sibling-cond-prep-amend-forced-2026-10-15`: F2's fourth
; exclusion (`siblingConditionCompareOnWire`) is predicate-agnostic — any
; icmp of a CondWire register against a literal, used only as branch
; conditions, whose value F2's own LVI edge pin forces to the CONSTANT seed.
; The rival `t = V` then holds V's forced value on every branch the arm runs
; in: the identity on the seed. Since `…-amend-straight-through-2026-10-15`
; the pin may be on EITHER edge; fcmp, off-wire registers, data-used compares
; and non-constant seeds stay loud.
;
;   if (x < 3) Ry(t,.3); if (x > 5) Ry(t,.7); bool k = (x > 8); if (k) Ry(t,.9); … cq_measure(k)
; `x > 8` is forced false on the arm edge, but it is also a register the
; program keeps (measured), so it is not a pure sibling condition: loud.
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
  %8 = icmp sgt i32 %1, 5
  br i1 %8, label %9, label %13

9:
  %10 = trunc nuw i8 %7 to i1
  %11 = call i1 @cq_theta_i1(i1 %10, double 0x3FE6666666666666)
  %12 = zext i1 %11 to i8
  br label %13

13:
  %14 = phi i8 [ %12, %9 ], [ %7, %6 ]
  %15 = icmp sgt i32 %1, 8
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
