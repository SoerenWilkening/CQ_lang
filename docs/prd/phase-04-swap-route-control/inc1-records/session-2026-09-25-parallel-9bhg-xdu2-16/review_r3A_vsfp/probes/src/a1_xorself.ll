target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8
  %5 = tail call i32 @atoi(ptr nocapture noundef %4)
  %6 = and i32 %5, 7
  %z = tail call i32 @cq_theta_si32(i32 noundef 2, double noundef 3.000000e-01)
  %7 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef 5.000000e-01)
  %9 = tail call i32 @h(i32 noundef %7, i32 noundef %5)
  %14 = tail call i32 @cq_theta_si32(i32 noundef %7, double noundef 0x3FE6666666666666)
  %15 = tail call i32 @cq_measure_si32(i32 noundef %14)
  %zm = tail call i32 @cq_measure_si32(i32 noundef %z)
  %16 = add nsw i32 %15, %9
  %17 = add nsw i32 %16, %zm
  ret i32 %17
}

declare i32 @atoi(ptr nocapture noundef)
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)

define i32 @h(i32 noundef %0, i32 noundef %1) {
  %d = xor i32 %0, 6
  %d2 = add i32 %d, %1
  %3 = icmp sgt i32 %0, 3
  br i1 %3, label %4, label %6

4:
  br label %6

6:
  %7 = add nsw i32 %1, 1
  ret i32 %7
}
