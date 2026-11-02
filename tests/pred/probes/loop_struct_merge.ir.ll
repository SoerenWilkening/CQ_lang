; USERCHECK f
; cq-pfpy (rules 9, 14, 26): a struct phi built in both arms of a quantum branch inside a classically bounded
; loop, merged field by field (lowerMergeFields from loops-classical; it stopped at pred's lowerMerge).
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

declare i32 @cq_theta_si32(i32, double)

declare i32 @cq_measure_si32(i32)

define i32 @f(i32 %0, i32 %1) {
  %3 = call i32 @cq_theta_si32(i32 %0, double 3.000000e-01)
  %4 = icmp sgt i32 %1, 0
  br i1 %4, label %5, label %25

5:                                                ; preds = %17, %2
  %6 = phi i32 [ 0, %2 ], [ %23, %17 ]
  %7 = phi i32 [ 0, %2 ], [ %22, %17 ]
  %8 = icmp sgt i32 %3, %6
  br i1 %8, label %9, label %13

9:                                                ; preds = %5
  %10 = add i32 %3, %6
  %11 = insertvalue { i32, i32 } undef, i32 %10, 0
  %12 = insertvalue { i32, i32 } %11, i32 7, 1
  br label %17

13:                                               ; preds = %5
  %14 = mul i32 %3, 3
  %15 = insertvalue { i32, i32 } undef, i32 %14, 0
  %16 = insertvalue { i32, i32 } %15, i32 %6, 1
  br label %17

17:                                               ; preds = %13, %9
  %18 = phi { i32, i32 } [ %12, %9 ], [ %16, %13 ]
  %19 = extractvalue { i32, i32 } %18, 0
  %20 = extractvalue { i32, i32 } %18, 1
  %21 = add i32 %19, %20
  %22 = add i32 %7, %21
  %23 = add nuw nsw i32 %6, 1
  %24 = icmp eq i32 %23, %1
  br i1 %24, label %25, label %5

25:                                               ; preds = %17, %2
  %26 = phi i32 [ 0, %2 ], [ %22, %17 ]
  %27 = call i32 @cq_measure_si32(i32 %26)
  %28 = call i32 @cq_measure_si32(i32 %3)
  %29 = add i32 %27, %28
  ret i32 %29
}
