target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i1 @cq_measure_i1(i1)
define i32 @main() {
entry:
  %q = call i32 @cq_theta_si32(i32 3, double 5.000000e-01)
  %q1 = add i32 %q, 1
  %t = icmp slt i32 %q, 6
  %r = select i1 %t, i32 %q1, i32 %q
  %m1 = call i32 @cq_measure_si32(i32 %r)
  %mt = call i1 @cq_measure_i1(i1 %t)
  %z = zext i1 %mt to i32
  %s = add i32 %m1, %z
  ret i32 %s
}
