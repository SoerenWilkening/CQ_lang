target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define double @f() {
  %1 = tail call double @cq_theta_f64(double 0.000000e+00, double 0.000000e+00)
  ret double 0.000000e+00
}

declare double @cq_theta_f64(double, double)

define i64 @cqsfi_fma_f64(i1 %0) {
  br i1 %0, label %12, label %2

2:                                                ; preds = %1
  %3 = icmp eq i16 0, 0
  br i1 %3, label %4, label %8

4:                                                ; preds = %2
  %5 = icmp eq i64 0, 0
  br i1 %5, label %6, label %7

6:                                                ; preds = %4
  ret i64 0

7:                                                ; preds = %4
  br label %8

8:                                                ; preds = %7, %2
  %9 = phi i16 [ 0, %2 ], [ 0, %7 ]
  br i1 false, label %12, label %10

10:                                               ; preds = %8
  %11 = select i1 %0, i16 0, i16 %9
  ret i64 0

12:                                               ; preds = %8, %1
  ret i64 0
}
