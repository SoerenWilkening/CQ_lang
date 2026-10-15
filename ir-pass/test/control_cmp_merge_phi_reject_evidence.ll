; control_cmp_merge_phi_reject_evidence.ll — DECLINE, ADVERSARIAL (bd
; test_C_libtooling-dm7f.77, R11 round 1 C-F2): the compare reads the claimed
; merge φ of `if (a) cq_theta(&b, .7)` AND a record of b's PRE-Ry value
; (`b0 = b * 3`, computed before the region):
;   int b0 = b * 3; if (a) cq_theta(&b, .7); if (b + b0 == 4) cq_theta(&t, .9);
; `condProvCoveredPhiGates` covers the claimed region's arm Ry only where it is
; NOT staling evidence on the provenance that bypasses the φ; here the `b0`
; path reaches b's pre-Ry name, whose wire that Ry moves, so the gate is evidence
; and the shipped decline stands.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: cq controlled lowering: condition predates a non-diagonal gate under quantum control

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @main() local_unnamed_addr {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01)
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 6.000000e-01)
  %3 = mul nsw i32 %2, 3
  br i1 %1, label %4, label %6

4:                                                ; preds = %0
  %5 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 0x3FE6666666666666)
  br label %6

6:                                                ; preds = %4, %0
  %7 = phi i32 [ %5, %4 ], [ %2, %0 ]
  %8 = add nsw i32 %7, %3
  %9 = icmp eq i32 %8, 4
  br i1 %9, label %10, label %12

10:                                               ; preds = %6
  %11 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 9.000000e-01)
  br label %12

12:                                               ; preds = %10, %6
  %13 = phi i1 [ %11, %10 ], [ false, %6 ]
  %14 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %1)
  %15 = zext i1 %14 to i32
  %16 = tail call i32 @cq_measure_si32(i32 noundef %7)
  %17 = shl i32 %16, 1
  %18 = or disjoint i32 %17, %15
  %19 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %13)
  %20 = select i1 %19, i32 4, i32 0
  %21 = or i32 %18, %20
  ret i32 %21
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr
