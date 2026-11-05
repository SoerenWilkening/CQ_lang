; CR rule 26: a loop-carried aggregate is one phi per field (a cmpxchg { i32, i1 } round a K-loop; __lockfile, fgets).
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i64 @cq_measure_sl(i64 noundef)
@c = internal global i32 3, align 4
define i32 @sweep_cx(i32 noundef %0) {
  %a = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 3.000000e-01)
  %x = and i32 %a, 7
  %i0 = cmpxchg ptr @c, i32 0, i32 %x seq_cst seq_cst, align 4
  br label %h
h:
  %v = phi { i32, i1 } [ %i0, %1 ], [ %n, %h ]
  %cur = extractvalue { i32, i1 } %v, 0
  %t = add i32 %cur, -1
  %n = cmpxchg ptr @c, i32 %cur, i32 %t seq_cst seq_cst, align 4
  %ok = extractvalue { i32, i1 } %n, 1
  %z = icmp eq i32 %t, 0
  br i1 %z, label %e, label %h
e:
  %s = sext i32 %t to i64
  %m = tail call i64 @cq_measure_sl(i64 noundef %s)
  %c2 = load i32, ptr @c
  %s2 = sext i32 %c2 to i64
  %m2 = tail call i64 @cq_measure_sl(i64 noundef %s2)
  ret i32 0
}
