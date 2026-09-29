target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

declare i32 @atoi(ptr nocapture noundef)
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare void @cq_phi(double noundef)
declare i32 @cq_measure_si32(i32 noundef)

define i32 @main(i32 noundef %argc, ptr noundef %argv) {
e:
  %a1p = getelementptr inbounds ptr, ptr %argv, i64 1
  %a1 = load ptr, ptr %a1p
  %m = call i32 @atoi(ptr noundef %a1)
  %m7 = and i32 %m, 7
  %q = call i32 @cq_theta_si32(i32 noundef %m7, double noundef 5.000000e-01)
  %p = mul nsw i32 %q, 3
  %r = call i32 @h(i32 noundef %p, i32 noundef %m)
  %u = xor i32 %p, %q
  %c = icmp eq i32 %u, 10
  br i1 %c, label %ph, label %j
ph:
  call void @cq_phi(double noundef 3.141590e+00)
  br label %j
j:
  %q2 = call i32 @cq_theta_si32(i32 noundef %q, double noundef 0x3FE6666666666666)
  %z = call i32 @cq_measure_si32(i32 noundef %q2)
  %zr = call i32 @cq_measure_si32(i32 noundef %r)
  %s = add nsw i32 %z, %zr
  ret i32 %s
}

define i32 @h(i32 noundef %a, i32 noundef %k) {
e:
  %r = tail call i32 @h2(i32 noundef %a, i32 noundef %k)
  ret i32 %r
}

define i32 @h2(i32 noundef "cq.probe.opaque" %x, i32 noundef %k) noinline {
e:
  %c = icmp sgt i32 %x, 3
  br i1 %c, label %t, label %f
t:
  br label %f
f:
  %r = add nsw i32 %k, 1
  ret i32 %r
}
