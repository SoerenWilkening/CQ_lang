; control_regcond_reject_guard_not_negation.ll — DECLINE, ADVERSARIAL (bd
; test_C_libtooling-dm7f.77, `substituteNegatedGuard`): hand IR from
; control_regcond_negated_guard_accept.ll with the guard's negation replaced by
; the IDENTITY `xor %c, false`. The substitution swaps the branch only for a
; genuine negation (`xor %c, true`); an identity must not be taken for one (that
; would fire the arm on the wrong branch). No substitution, so the rail
; condition still sits on the rotated register: the pre-dm7f.77 decline.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: cq controlled lowering: condition predates a non-diagonal gate under quantum control

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define range(i32 0, 4) i32 @main() local_unnamed_addr {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01)
  %n = xor i1 %1, false
  br i1 %1, label %4, label %2

2:                                                ; preds = %0
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %1, double noundef 0x3FE6666666666666)
  br label %4

4:                                                ; preds = %2, %0
  %5 = phi i1 [ %3, %2 ], [ %1, %0 ]
  %6 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %5)
  %7 = zext i1 %6 to i32
  %8 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %n)
  %9 = select i1 %8, i32 2, i32 0
  %10 = or disjoint i32 %9, %7
  ret i32 %10
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr
