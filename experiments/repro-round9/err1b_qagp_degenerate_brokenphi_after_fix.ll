target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

declare void @gsl_error()

define i32 @gsl_integration_qagp(double %0, i1 %1) {
  br i1 false, label %._crit_edge, label %3

._crit_edge:                                      ; preds = %2
  br label %5

3:                                                ; preds = %2
  %4 = fcmp olt double %0, 0.000000e+00
  br i1 %4, label %15, label %5

5:                                                ; preds = %6, %3, %._crit_edge
  br i1 false, label %8, label %6

6:                                                ; preds = %5
  br i1 %1, label %7, label %5

7:                                                ; preds = %6
  call void @gsl_error()
  br label %15

8:                                                ; preds = %5
  br i1 %1, label %13, label %9

9:                                                ; preds = %9, %8
  %10 = phi double [ %12, %9 ], [ 0.000000e+00, %8 ]
  %11 = load double, ptr null, align 8
  %12 = fadd double 0.000000e+00, 0.000000e+00
  br i1 %1, label %13, label %9

13:                                               ; preds = %9, %8
  %14 = phi double [ 0.000000e+00, %8 ], [ %12, %9 ]
  store double %14, ptr null, align 8
  br label %15

15:                                               ; preds = %13, %7, %3
  ret i32 0
}
