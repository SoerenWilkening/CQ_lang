; F-U1 attack: the theta result is an incoming of TWO different phis. The SECOND
; phi belongs to an unrelated merge whose undef incoming is not the seed's object.
target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_measure_i32(i32)

define i1 @example(i1 %c, i1 %x) {
entry:
  %t = call i1 @cq_theta_i1(i1 undef, double 5.000000e-01)
  br i1 %t, label %a, label %j
a:
  br label %j
j:
  %m1 = phi i1 [ %t, %entry ], [ undef, %a ]
  br i1 %c, label %p, label %q
p:
  br label %k
q:
  br label %k
k:
  %m2 = phi i1 [ %t, %p ], [ undef, %q ]
  %r1 = call i1 @cq_measure_i1(i1 %m1)
  %r2 = call i1 @cq_measure_i1(i1 %m2)
  %o = and i1 %r1, %r2
  ret i1 %o
}
