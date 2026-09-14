target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)
declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef)
declare zeroext i1 @cq_measure_i1(i1 noundef zeroext)
declare void @cq_phi(double noundef)
define i32 @example(i1 %c) {
entry:
  br i1 %c, label %a, label %j
a:
  %b = call zeroext i1 @cq_theta_i1(i1 noundef zeroext undef, double noundef 5.000000e-01)
  br label %j
j:
  %p = phi i1 [ %b, %a ], [ undef, %entry ]
  br i1 %p, label %g, label %k
g:
  call void @cq_phi(double noundef 3.140000e+00)
  br label %k
k:
  %m = call zeroext i1 @cq_measure_i1(i1 noundef zeroext %p)
  %z = zext i1 %m to i32
  ret i32 %z
}
