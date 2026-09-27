target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @cq_phi(double)
declare i32 @atoi(ptr)
define i32 @main(i32 noundef %0, ptr noundef %1) {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8
  %m = call i32 @atoi(ptr %4)
  %mm = and i32 %m, 7
  %q = call i32 @cq_theta_si32(i32 %mm, double 5.000000e-01)
  %p = mul i32 %q, 3
  %t = trunc i32 %p to i16
  %r = call i32 @hd(i16 noundef zeroext %t, i32 noundef %m)
  %u = xor i32 %p, %q
  %c = icmp eq i32 %u, 10
  br i1 %c, label %ph, label %j
ph:
  call void @cq_phi(double 3.14159)
  br label %j
j:
  %q2 = call i32 @cq_theta_si32(i32 %q, double 7.000000e-01)
  %z = call i32 @cq_measure_si32(i32 %q2)
  %s = add i32 %r, %z
  ret i32 %s
}
define i32 @hd(i16 noundef zeroext %a, i32 noundef %k) {
  %c = icmp ugt i16 %a, 3
  br i1 %c, label %x, label %y
x:
  br label %y
y:
  %r = add nsw i32 %k, 1
  ret i32 %r
}
