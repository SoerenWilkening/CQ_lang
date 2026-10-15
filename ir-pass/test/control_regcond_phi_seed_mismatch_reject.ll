; control_regcond_phi_seed_mismatch_reject.ll — DECLINE, ADVERSARIAL (bd
; test_C_libtooling-dm7f.77, R11 round 1 B-F1): a merge whose constant incoming
; is NOT the prep's seed (`if (a) cq_theta(&b, .8); else b = 1;` with b = 0), so
; `phi [Ry(false), true]` is two values, never one wire, and `b ^= c` must not
; take it as an in-place target. It stays loud at F1 (the seed fence), upstream
; of the in-place round; the single-wire seed-identity check is that fence's
; defence in depth for the in-place question.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: cq controlled lowering: state prep seed does not match the merge incoming under quantum control

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define range(i32 0, 8) i32 @main() local_unnamed_addr {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 1.100000e+00)
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 3.000000e-01)
  br i1 %1, label %3, label %6

3:                                                ; preds = %0
  %4 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 8.000000e-01)
  %5 = zext i1 %4 to i32
  br label %6

6:                                                ; preds = %0, %3
  %7 = phi i32 [ %5, %3 ], [ 1, %0 ]
  %8 = zext i1 %2 to i32
  %9 = icmp ne i32 %7, %8
  %10 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %2, double noundef 4.000000e-01)
  %11 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %1)
  %12 = zext i1 %11 to i32
  %13 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %9)
  %14 = select i1 %13, i32 2, i32 0
  %15 = or disjoint i32 %14, %12
  %16 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %10)
  %17 = select i1 %16, i32 4, i32 0
  %18 = or disjoint i32 %15, %17
  ret i32 %18
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr
