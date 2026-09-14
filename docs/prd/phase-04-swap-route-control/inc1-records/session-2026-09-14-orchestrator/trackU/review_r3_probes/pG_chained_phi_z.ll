target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)
define i32 @example(i1 %c, i1 %d) {
entry:
  %q = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 9.000000e-01)
  %cc = icmp eq i32 %q, 3
  br i1 %cc, label %arm, label %m1
arm:
  %rt = tail call i32 @cq_theta_si32(i32 0, double noundef 5.000000e-01)
  br label %m1
m1:
  %p1 = phi i32 [ %rt, %arm ], [ 0, %entry ]
  br i1 %d, label %e2, label %m2
e2:
  br label %m2
m2:
  %p2 = phi i32 [ %p1, %m1 ], [ undef, %e2 ]
  %m = tail call i32 @cq_measure_si32(i32 noundef %p2)
  ret i32 %m
}
