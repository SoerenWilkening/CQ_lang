target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)
define i32 @example() {
entry:
  %c = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 9.000000e-01)
  %cc = icmp eq i32 %c, 3
  br i1 %cc, label %arm, label %merge
arm:
  %rt = tail call i32 @cq_theta_si32(i32 0, double noundef 5.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ 0, %entry ]
  %m = tail call i32 @cq_measure_si32(i32 noundef %rm)
  ret i32 %m
}
