target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"
@K = internal global i32 7, align 4
declare i32 @cq_theta_si32(i32, double)
declare void @cq_phi(double)
declare i32 @atoi(ptr)
define i32 @w(i32 %m, i32 %k) noinline {
  %a = and i32 %m, 7
  %q = call i32 @cq_theta_si32(i32 %a, double 5.000000e-01)
  %p = mul nsw i32 %q, 3
  %u = xor i32 %p, %q
  %c = icmp eq i32 %u, 10
  br i1 %c, label %t, label %j
t:
  call void @cq_phi(double 3.141590e+00)
  br label %j
j:
  %r = add nsw i32 %k, 1
  ret i32 %r
}
define i32 @h2(i32 %x, i32 %k) noinline {
  %c = icmp sgt i32 %x, 3
  br i1 %c, label %t, label %j
t:
  %v = load volatile i32, ptr @K
  br label %j
j:
  %r = add nsw i32 %k, 1
  ret i32 %r
}
define i32 @main(i32 %argc, ptr %argv) {
  %g = getelementptr inbounds i8, ptr %argv, i64 8
  %s = load ptr, ptr %g
  %m = call i32 @atoi(ptr %s)
  %r = call i32 @w(i32 %m, i32 %m)
  %d = sub i32 %r, %m
  ret i32 %d
}
