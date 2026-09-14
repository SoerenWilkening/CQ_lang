target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)
define i32 @example(i32 %s) {
entry:
  %c = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 9.000000e-01)
  %cc = icmp eq i32 %c, 3
  br i1 %cc, label %a1, label %a2
a1:
  %t1 = tail call i32 @cq_theta_si32(i32 0, double noundef 5.000000e-01)
  br label %merge
a2:
  %t2 = tail call i32 @cq_theta_si32(i32 0, double noundef 2.500000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %t1, %a1 ], [ %t2, %a2 ]
  %m = tail call i32 @cq_measure_si32(i32 noundef %rm)
  ret i32 %m
}
