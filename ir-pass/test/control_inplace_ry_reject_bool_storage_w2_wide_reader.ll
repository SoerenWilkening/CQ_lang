; control_inplace_ry_reject_bool_storage_w2_wide_reader.ll — DECLINE: an i8 web read by a non-bit-0 reader.
;
; bd test_C_libtooling-dm7f.53 — a BOUNDARY of `narrowBoolStoragePhis`
; (BoolStorageNarrow.h). The narrowing is accept-only: a web that fails a
; condition is left BYTE-UNTOUCHED, so the region reaches its pre-dm7f.53 loud
; owner with the pre-dm7f.53 string (the retired-route message, bd OQ-13).
;
; (W2): `add i8 %12, 1` reads the storage value as an integer; the narrowing
; vocabulary is trunc-to-i1 / zext / the low-bit icmp only. Hand-edited from
; the p9 IR. RETIREMENT TRIGGER: widening W2 to arithmetic readers (rewrite as
; zext of the narrowed phi) flips this file — measure, then flip.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_measure_si32(i32)

define i32 @example() {
  %1 = call i1 @cq_theta_i1(i1 false, double 1.000000e+00)
  br i1 %1, label %2, label %5

2:
  %3 = call i1 @cq_theta_i1(i1 false, double 3.000000e-01)
  %4 = zext i1 %3 to i8
  br label %5

5:
  %6 = phi i8 [ %4, %2 ], [ 0, %0 ]
  br i1 %1, label %11, label %7

7:
  %8 = trunc nuw i8 %6 to i1
  %9 = call i1 @cq_theta_i1(i1 %8, double 0x3FE6666666666666)
  %10 = zext i1 %9 to i8
  br label %11

11:
  %12 = phi i8 [ %6, %5 ], [ %10, %7 ]
  %13 = call i1 @cq_measure_i1(i1 %1)
  %14 = zext i1 %13 to i32
  %15 = add i8 %12, 1
  %16 = zext i8 %15 to i32
  %17 = call i32 @cq_measure_si32(i32 %16)
  %18 = add nuw nsw i32 %17, %14
  ret i32 %18
}

; CHECK: cq controlled lowering: value-arm swap-route under quantum control
