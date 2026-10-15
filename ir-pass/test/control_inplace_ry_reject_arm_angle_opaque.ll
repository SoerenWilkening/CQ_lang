; control_inplace_ry_reject_arm_angle_opaque.ll — DECLINE, ADVERSARIAL (bd
; test_C_libtooling-dm7f.77, ArmAngleHoist.h): hand IR from
; control_inplace_ry_arm_angle_cone_accept.ll with the arm's `llvm.acos` replaced
; by an opaque external call. (H2) refuses an instruction LLVM does not prove
; speculatable (`isSafeToSpeculativelyExecute`), so the arm keeps its stray op
; and the pre-dm7f.77 decline stands: a call may not run on the other branch.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: cq controlled lowering: control flow under quantum control

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define range(i32 0, 4) i32 @main() local_unnamed_addr {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01)
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 3.000000e-01)
  br i1 %1, label %3, label %7

3:                                                ; preds = %0
  %4 = tail call double @ext_angle(double 0x3FE279A74590331C)
  %5 = fmul double %4, 2.000000e+00
  %6 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %2, double noundef %5)
  br label %7

7:                                                ; preds = %3, %0
  %8 = phi i1 [ %6, %3 ], [ %2, %0 ]
  %9 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %1)
  %10 = zext i1 %9 to i32
  %11 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %8)
  %12 = select i1 %11, i32 2, i32 0
  %13 = or disjoint i32 %12, %10
  ret i32 %13
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr

declare double @llvm.acos.f64(double)

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr

declare double @ext_angle(double)
