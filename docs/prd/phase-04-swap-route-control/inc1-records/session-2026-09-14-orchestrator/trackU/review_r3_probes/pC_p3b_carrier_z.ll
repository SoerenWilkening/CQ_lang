target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)
define i32 @example() {
entry:
  %1 = tail call i32 @cq_theta_si32(i32 0, double noundef 5.000000e-01)
  %2 = icmp eq i32 %1, 1
  br i1 %2, label %5, label %3
3:
  %4 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  br label %5
5:
  %6 = phi i32 [ %1, %3 ], [ 0, %entry ]
  %7 = phi i32 [ %4, %3 ], [ 0, %entry ]
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7)
  %11 = tail call i32 @cq_measure_si32(i32 noundef %6)
  %12 = add nsw i32 %8, %11
  ret i32 %12
}
