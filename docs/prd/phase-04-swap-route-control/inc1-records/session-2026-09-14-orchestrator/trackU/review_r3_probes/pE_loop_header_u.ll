target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)
declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef)
declare zeroext i1 @cq_measure_i1(i1 noundef zeroext)
declare void @cq_phi(double noundef)
define i32 @example() {
entry:
  br label %h
h:
  %i = phi i32 [ 0, %entry ], [ %i1, %h ]
  %r = phi i32 [ undef, %entry ], [ %t, %h ]
  %t = call i32 @cq_theta_si32(i32 undef, double 5.000000e-01)
  %i1 = add nuw nsw i32 %i, 1
  %e = icmp eq i32 %i1, 3
  br i1 %e, label %x, label %h
x:
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
