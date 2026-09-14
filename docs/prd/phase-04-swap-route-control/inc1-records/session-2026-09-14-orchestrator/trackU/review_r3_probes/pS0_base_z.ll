

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef)
declare zeroext i1 @cq_measure_i1(i1 noundef zeroext)
declare i32 @cq_measure_si32(i32 noundef)

define i32 @main() local_unnamed_addr {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01)
  br i1 %1, label %4, label %2

2:
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01)
  br label %4

4:
  %5 = phi i32 [ 5, %2 ], [ 2, %0 ]
  %6 = phi i1 [ %3, %2 ], [ false, %0 ]
  %7 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %1)
  %8 = zext i1 %7 to i32
  %9 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %6)
  %10 = zext i1 %9 to i32
  %11 = add nuw nsw i32 %10, %8
  %12 = tail call i32 @cq_measure_si32(i32 noundef %5)
  %13 = add nsw i32 %11, %12
  ret i32 %13
}
