; F-U1 attack: a phi with THREE incomings, one of them undef, carrying the theta.
target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_measure_i32(i32)

define i1 @example(i1 %c, i1 %d, i1 %x) {
entry:
  %t = call i1 @cq_theta_i1(i1 undef, double 5.000000e-01)
  br i1 %t, label %a, label %e2
e2:
  br i1 %d, label %b, label %c3
a:
  br label %j
b:
  br label %j
c3:
  br label %j
j:
  %m = phi i1 [ %t, %a ], [ undef, %b ], [ %x, %c3 ]
  %r = call i1 @cq_measure_i1(i1 %m)
  ret i1 %r
}
