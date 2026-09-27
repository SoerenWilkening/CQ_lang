; t2: fold-1 phi has EQUAL incomings %t (a LIVE tainted compare the user measures); the fold-2 seed is
; RAUW'd to %t, which must survive (it is measured) and the fold-2 branch on it must lower as control.
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"
@K = internal global i32 5, align 4
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i1 @cq_measure_i1(i1)
define i32 @main() {
entry:
  %q = call i32 @cq_theta_si32(i32 3, double 5.000000e-01)
  %q1 = add i32 %q, 1
  %c = icmp sgt i32 %q, 3
  %t = icmp slt i32 %q, 6
  br i1 %c, label %a1, label %s1
a1:
  %k1 = load volatile i32, ptr @K, align 4
  br label %s1
s1:
  %p = phi i1 [ %t, %a1 ], [ %t, %entry ]
  br i1 %p, label %a2, label %s2
a2:
  %k2 = load volatile i32, ptr @K, align 4
  br label %s2
s2:
  %r = phi i32 [ %q1, %a2 ], [ %q, %s1 ]
  %m1 = call i32 @cq_measure_si32(i32 %r)
  %mt = call i1 @cq_measure_i1(i1 %t)
  %z = zext i1 %mt to i32
  %s = add i32 %m1, %z
  ret i32 %s
}
