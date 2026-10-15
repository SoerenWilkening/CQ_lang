; control_inplace_ry_reject_seq_counter_f2_offwire_shift.ll — DECLINE: sibling pin through a shift.
;
; bd test_C_libtooling-dm7f.53 — the BOUNDARY of the sibling-condition
; exclusion (ruling-dm7f53-p4-sibling-cond-prep-2026-10-15: "seeds pinned via
; off-wire registers (shift, cast, sideways rewrite, intrinsic, fp) stay
; loud"). Region 1 is `if (x == 0) cq_theta(&t,.3)` with t fresh; the second
; region's condition is forced false (= the seed) on region 1's arm edge, but
; through a value that is NOT a `CondWire` member, so F2 keeps the collision.
;
; if ((x >> 1) == 3) cq_theta(&t,.7);  -O1: icmp eq (and x, -2), 6 — the `and` is off-wire.
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
