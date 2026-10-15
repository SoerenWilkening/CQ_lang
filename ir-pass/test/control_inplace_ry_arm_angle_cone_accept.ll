; control_inplace_ry_arm_angle_cone_accept.ll — ACCEPT (bd test_C_libtooling-
; dm7f.77, ArmAngleHoist.h): a controlled Ry whose ANGLE is computed in the arm.
;
; Source (clang -O1 -include CQ.h, <math.h>):
;   bool a = 0, b = 0; cq_theta(&a, .5); cq_theta(&b, .3);
;   if (a) cq_theta(&b, 2.0 * acos(sqrt(1.0 / 3)));
;   return cq_measure(a) | (cq_measure(b) << 1);
;
; -O1 folds the sqrt but leaves `llvm.acos` + `fmul` in the arm, and every
; rotation clause wants the theta to be the whole arm, so main 27aaf1e1 declined
; `control flow` (the same program with a literal angle lowered). The untainted,
; speculatable angle cone is hoisted into the pred before detection. Analytic
; (trace vs textbook, identical to 12 digits): P(a,b) = 00: 0.917826423653,
; 01: 0.020964857293, 10: 0.012331579261, 11: 0.048877139794.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NOERR --allow-empty < %t.err
; NOERR-NOT: error
; CHECK-LABEL: define range(i32 0, 4) i32 @main()
; CHECK-NEXT:  %[[A:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT:  call void @cqrt_ry_i1(i32 %[[A]], double 5.000000e-01)
; CHECK-NEXT:  %[[B:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT:  call void @cqrt_ry_i1(i32 %[[B]], double 3.000000e-01)
; CHECK-NEXT:  %[[X:[a-zA-Z0-9_.]+]] = tail call double @llvm.acos.f64(double 0x3FE279A74590331C)
; CHECK-NEXT:  %[[Y:[a-zA-Z0-9_.]+]] = fmul double %[[X]], 2.000000e+00
; CHECK-NEXT:  call void @cqrt_ry_i1_controlled(i32 %[[A]], i32 %[[B]], double %[[Y]])

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define range(i32 0, 4) i32 @main() local_unnamed_addr {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01)
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 3.000000e-01)
  br i1 %1, label %3, label %7

3:                                                ; preds = %0
  %4 = tail call double @llvm.acos.f64(double 0x3FE279A74590331C)
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
