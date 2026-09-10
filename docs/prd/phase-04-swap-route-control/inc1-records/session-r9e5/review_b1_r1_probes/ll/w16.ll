target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"
declare zeroext i1 @cq_theta_i1(i1, double)
declare i32 @cq_theta_si32(i32, double)
declare zeroext i1 @cq_measure_i1(i1)
declare i32 @cq_measure_si32(i32)
declare void @cq_phi(double)

; the COMPARE twin of w15 (a second register as the select condition)
define i32 @main() {
entry:
  %q = call i32 @cq_theta_si32(i32 3, double 2.000000e-01)
  %r = call i32 @cq_theta_si32(i32 4, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %join
arm:
  call void @cq_phi(double 9.000000e-01)
  br label %join
join:
  %d = icmp sgt i32 %r, 2
  %s = select i1 %d, i32 2, i32 5
  %m = call i32 @cq_measure_si32(i32 %s)
  %n = call i32 @cq_measure_si32(i32 %r)
  %o = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}
