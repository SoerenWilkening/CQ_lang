target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @gsl_sf_coulomb_wave_FG_e(i1 %0, i1 %1) {
  br i1 %0, label %3, label %4

3:                                                ; preds = %2
  ret i32 0

4:                                                ; preds = %2
  br i1 %1, label %5, label %8

5:                                                ; preds = %4
  %6 = fcmp olt double 0.000000e+00, 0.000000e+00
  br i1 %6, label %7, label %8

7:                                                ; preds = %5
  ret i32 0

8:                                                ; preds = %9, %5, %4
  tail call void null(ptr null, ptr null, i32 0, i32 0)
  br i1 false, label %9, label %10

9:                                                ; preds = %8
  br i1 false, label %8, label %10

10:                                               ; preds = %9, %8
  %11 = tail call double null(double 0.000000e+00, double 0.000000e+00)
  ret i32 0
}
