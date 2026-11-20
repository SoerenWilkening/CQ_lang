target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"
define i32 @s_switch(i32 noundef %0, double noundef %1, i32 noundef %s) {
entry:
  %x = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1)
  switch i32 %s, label %other [
    i32 1, label %join
    i32 2, label %join
  ]
other:
  %y = add i32 %x, 5
  br label %join
join:
  %r = phi i32 [ %x, %entry ], [ %x, %entry ], [ %y, %other ]
  %m = tail call i32 @cq_measure_ui32(i32 noundef %r)
  ret i32 %m
}
declare i32 @cq_theta_ui32(i32 noundef, double noundef)
declare i32 @cq_measure_ui32(i32 noundef)
