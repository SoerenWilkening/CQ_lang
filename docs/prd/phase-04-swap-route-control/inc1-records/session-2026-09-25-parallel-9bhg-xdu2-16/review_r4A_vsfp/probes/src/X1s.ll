target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"
declare i32 @atoi(ptr nocapture noundef)
declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef)
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)
define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8
  %5 = tail call i32 @atoi(ptr nocapture noundef %4)
  %6 = and i32 %5, 1
  %7 = icmp ne i32 %6, 0
  %b1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %7, double noundef 5.000000e-01)
  %b2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 6.000000e-01)
  %b3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext true, double noundef 7.000000e-01)
  %12 = and i32 %5, 7
  %q = tail call i32 @cq_theta_si32(i32 noundef %12, double noundef 5.000000e-01)
  %s = select i1 %b1, i1 %b2, i1 %b3
  %r0 = tail call i32 @hb(i1 noundef zeroext %s, i32 noundef %5)
  %v = select i1 %s, i32 %q, i32 3
  %mv = tail call i32 @cq_measure_si32(i32 noundef %v)
  %r = add nsw i32 %mv, %r0
  ret i32 %r
}
define i32 @hb(i1 noundef zeroext %x, i32 noundef %k) {
  %c = icmp sgt i32 %k, 3
  %c2 = and i1 %c, %x
  br i1 %c2, label %e, label %m
e:
  br label %m
m:
  %r = add nsw i32 %k, 1
  ret i32 %r
}
