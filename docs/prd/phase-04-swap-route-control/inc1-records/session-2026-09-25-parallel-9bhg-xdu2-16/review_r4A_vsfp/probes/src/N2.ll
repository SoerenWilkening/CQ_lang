target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"
declare i32 @atoi(ptr nocapture noundef)
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)
declare void @cq_phi(double noundef)

define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8
  %5 = tail call i32 @atoi(ptr nocapture noundef %4)
  %6 = and i32 %5, 7
  %z = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef 3.000000e-01)
  %q = tail call i32 @cq_theta_si32(i32 noundef 2, double noundef 5.000000e-01)
  %r = tail call i32 @h(i32 noundef %q, i32 noundef %z)
  %q2 = tail call i32 @cq_theta_si32(i32 noundef %q, double noundef 0x3FE6666666666666)
  %mq = tail call i32 @cq_measure_si32(i32 noundef %q2)
  %mr = tail call i32 @cq_measure_si32(i32 noundef %r)
  %mz = tail call i32 @cq_measure_si32(i32 noundef %z)
  %s1 = add nsw i32 %mq, %mr
  %s2 = add nsw i32 %s1, %mz
  ret i32 %s2
}

define i32 @h(i32 noundef %a, i32 noundef %b) {
  %t = mul nsw i32 %a, 5
  %r0 = tail call i32 @g(i32 noundef %t, i32 noundef %b)
  %r = add nsw i32 %r0, %a
  ret i32 %r
}
define i32 @g(i32 noundef %x, i32 noundef %y) {
  %c = icmp sgt i32 %x, 3
  br i1 %c, label %e, label %m
e:
  br label %m
m:
  %r = mul nsw i32 %y, 3
  ret i32 %r
}
