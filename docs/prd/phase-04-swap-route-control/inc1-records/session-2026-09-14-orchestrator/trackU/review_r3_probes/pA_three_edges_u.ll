target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)
declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef)
declare zeroext i1 @cq_measure_i1(i1 noundef zeroext)
declare void @cq_phi(double noundef)
define i32 @example(i32 %c) {
entry:
  switch i32 %c, label %d [ i32 1, label %a
                            i32 2, label %b ]
a:
  %t = call i32 @cq_theta_si32(i32 undef, double 5.000000e-01)
  br label %j
b:
  br label %j
d:
  br label %j
j:
  %p = phi i32 [ %t, %a ], [ undef, %b ], [ 7, %d ]
  %m = call i32 @cq_measure_si32(i32 %p)
  ret i32 %m
}
