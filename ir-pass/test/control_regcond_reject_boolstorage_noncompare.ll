; control_regcond_reject_boolstorage_noncompare.ll — DECLINE, ADVERSARIAL (bd
; test_C_libtooling-dm7f.77, BoolStorageNarrow.cpp D1): hand IR from
; control_regcond_boolstorage_scs21_accept.ll with the compare's other operand
; replaced by the constant 2. D1 narrows only a compare against a value that is
; itself provably 0 or 1 (a web member, a `zext i1`, the constant 0 or 1); `P != 2`
; is not a Boolean compare, so the web is not narrowed and the `_Bool` storage
; width keeps the pre-dm7f.77 decline.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: cq controlled lowering: value-arm swap-route under quantum control

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define range(i32 0, 4) i32 @main() local_unnamed_addr {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01)
  br i1 %1, label %2, label %5

2:                                                ; preds = %0
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 6.000000e-01)
  %4 = zext i1 %3 to i8
  br label %5

5:                                                ; preds = %2, %0
  %6 = phi i8 [ %4, %2 ], [ 0, %0 ]
  %7 = zext i1 %1 to i8
  %8 = icmp ne i8 %6, 2
  br i1 %8, label %9, label %13

9:                                                ; preds = %5
  %10 = trunc nuw i8 %6 to i1
  %11 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %10, double noundef 0x3FE6666666666666)
  %12 = zext i1 %11 to i8
  br label %13

13:                                               ; preds = %9, %5
  %14 = phi i8 [ %12, %9 ], [ %6, %5 ]
  %15 = trunc nuw i8 %14 to i1
  %16 = xor i1 %8, %15
  %17 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %15)
  %18 = zext i1 %17 to i32
  %19 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %16)
  %20 = select i1 %19, i32 2, i32 0
  %21 = or disjoint i32 %20, %18
  ret i32 %21
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr
