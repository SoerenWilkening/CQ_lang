; control_inplace_ry_reject_seq_counter_f2_offwire_datause.ll — DECLINE: sibling pin through a compare with a data use.
;
; bd test_C_libtooling-dm7f.53 — the BOUNDARY of the sibling-condition
; exclusion (ruling-dm7f53-p4-sibling-cond-prep-2026-10-15: "seeds pinned via
; off-wire registers (shift, cast, sideways rewrite, intrinsic, fp) stay
; loud"). Region 1 is `if (x == 0) cq_theta(&t,.3)` with t fresh; the second
; region's condition is forced false (= the seed) on region 1's arm edge, but
; through a value that is NOT a `CondWire` member, so F2 keeps the collision.
;
; bool k = (x == 1); if (x == 0) Ry(t,.3); if (k) Ry(t,.7); ... cq_measure(k) — the compare is on-wire but also DATA (a register the program keeps), so it is not a pure sibling condition.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare i32 @cq_theta_si32(i32, double)
declare i1 @cq_theta_i1(i1, double)
declare i32 @cq_measure_si32(i32)
declare i1 @cq_measure_i1(i1)

define i32 @example() {
  %1 = call i32 @cq_theta_si32(i32 0, double 1.000000e+00)
  %2 = icmp eq i32 %1, 1
  %3 = icmp eq i32 %1, 0
  br i1 %3, label %4, label %7

4:
  %5 = call i1 @cq_theta_i1(i1 false, double 3.000000e-01)
  %6 = zext i1 %5 to i8
  br label %7

7:
  %8 = phi i8 [ %6, %4 ], [ 0, %0 ]
  br i1 %2, label %9, label %13

9:
  %10 = trunc nuw i8 %8 to i1
  %11 = call i1 @cq_theta_i1(i1 %10, double 0x3FE6666666666666)
  %12 = zext i1 %11 to i8
  br label %13

13:
  %14 = phi i8 [ %12, %9 ], [ %8, %7 ]
  %15 = call i32 @cq_measure_si32(i32 %1)
  %16 = trunc nuw i8 %14 to i1
  %17 = call i1 @cq_measure_i1(i1 %16)
  %18 = zext i1 %17 to i32
  %19 = add nsw i32 %15, %18
  %20 = call i1 @cq_measure_i1(i1 %2)
  %21 = zext i1 %20 to i32
  %22 = add nsw i32 %19, %21
  ret i32 %22
}

; CHECK: cq controlled lowering: state prep seed is proven equal to the condition register under quantum control
