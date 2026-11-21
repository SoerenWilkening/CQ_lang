target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @gsl_sf_hermite_prob_array_deriv(i1 %0) {
  br i1 %0, label %2, label %5

2:                                                ; preds = %1
  br i1 false, label %3, label %4

3:                                                ; preds = %3, %2
  br i1 %0, label %5, label %3

4:                                                ; preds = %2
  ret i32 0

5:                                                ; preds = %3, %1
  %6 = phi i32 [ 0, %3 ], [ 1, %1 ]
  ret i32 %6
}
