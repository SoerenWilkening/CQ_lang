target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"
@K = internal global i32 5, align 4
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @main() {
entry:
  %q = call i32 @cq_theta_si32(i32 3, double 5.000000e-01)
  %c = icmp sgt i32 %q, 3
  %r = select i1 %c, i32 5, i32 9
  br label %merge
merge:
  %bc = bitcast i32 %r to i32
  %r2 = call i32 @cq_theta_si32(i32 %r, double 7.000000e-01)
  %m1 = call i32 @cq_measure_si32(i32 %bc)
  %m2 = call i32 @cq_measure_si32(i32 %r2)
  %m3 = call i32 @cq_measure_si32(i32 %q)
  %s = add i32 %m1, %m2
  %s2 = add i32 %s, %m3
  ret i32 %s2
}
