; CR rule 16: the result rail of an effect entry is never freed, also where rule 6 would clean it (add under a quantum predicate; malloc).
; CHECK main2: cqrt_tape_effect_i64_controlled
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"
declare i64 @cq_theta_ul(i64 noundef, double noundef)
declare i64 @cq_measure_sl(i64 noundef)
declare i64 @host(i64 noundef)
@g = internal global i64 0
define i32 @main2(i64 noundef %0) {
  %2 = tail call i64 @cq_theta_ul(i64 noundef %0, double noundef 3.000000e-01)
  %c = icmp ugt i64 %2, 5
  br i1 %c, label %a, label %b
a:
  %r = tail call i64 @host(i64 noundef 12)
  %s = add i64 %r, 1
  store i64 %s, ptr @g
  br label %b
b:
  %p = phi i64 [ %s, %a ], [ -1, %1 ]
  %m = tail call i64 @cq_measure_sl(i64 noundef %p)
  ret i32 0
}
