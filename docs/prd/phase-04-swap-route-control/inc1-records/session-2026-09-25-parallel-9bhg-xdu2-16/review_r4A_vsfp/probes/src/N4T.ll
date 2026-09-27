target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"
declare i32 @atoi(ptr nocapture noundef)
declare double @cq_theta_f64(double noundef, double noundef)
declare double @cq_measure_f64(double noundef)
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)
define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8
  %5 = tail call i32 @atoi(ptr nocapture noundef %4)
  %6 = and i32 %5, 7
  %7 = uitofp nneg i32 %6 to double
  %zd = tail call double @cq_theta_f64(double noundef %7, double noundef 3.000000e-01)
  %zi = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef 3.500000e-01)
  %qd = tail call double @cq_theta_f64(double noundef 1.500000e+00, double noundef 5.000000e-01)
  %r = tail call i32 @h(i32 noundef %zi)
  %q2 = tail call double @cq_theta_f64(double noundef %qd, double noundef 0x3FE6666666666666)
  %mq = tail call double @cq_measure_f64(double noundef %q2)
  %mqi = fptosi double %mq to i32
  %mri = tail call i32 @cq_measure_si32(i32 noundef %r)
  %mzd = tail call double @cq_measure_f64(double noundef %zd)
  %mzdi = fptosi double %mzd to i32
  %mzi = tail call i32 @cq_measure_si32(i32 noundef %zi)
  %s1 = add nsw i32 %mqi, %mri
  %s2 = add nsw i32 %s1, %mzdi
  %s3 = add nsw i32 %s2, %mzi
  ret i32 %s3
}

define i32 @h(i32 noundef %b) {
  %r = tail call i32 @g(i32 noundef %b)
  ret i32 %r
}
define i32 @g(i32 noundef %y) {
  %r = mul nsw i32 %y, 3
  ret i32 %r
}
