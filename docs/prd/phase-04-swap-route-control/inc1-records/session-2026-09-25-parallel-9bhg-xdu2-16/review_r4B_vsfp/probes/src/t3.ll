; t3: fold-1 phi has EQUAL incomings = an ARGUMENT; the fold-2 seed follows the RAUW to the Argument.
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"
@K = internal global i32 5, align 4
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @main(i1 %b) {
entry:
  %q = call i32 @cq_theta_si32(i32 3, double 5.000000e-01)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %a1, label %s1
a1:
  %k1 = load volatile i32, ptr @K, align 4
  br label %s1
s1:
  %p = phi i1 [ %b, %a1 ], [ %b, %entry ]
  br i1 %p, label %a2, label %s2
a2:
  %k2 = load volatile i32, ptr @K, align 4
  br label %s2
s2:
  %m1 = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m1
}
