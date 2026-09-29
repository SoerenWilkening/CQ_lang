target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"
declare i32 @atoi(ptr nocapture noundef)
declare double @cq_theta_f64(double noundef, double noundef)
declare void @cq_phi(double noundef)
declare double @cq_measure_f64(double noundef)
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)
define i32 @main(i32 noundef %argc, ptr noundef %argv) {
e:
  %a1p = getelementptr inbounds ptr, ptr %argv, i64 1
  %a1 = load ptr, ptr %a1p
  %m = call i32 @atoi(ptr noundef %a1)
  %m7 = and i32 %m, 7
  %md = sitofp i32 %m7 to double
  %q = call double @cq_theta_f64(double noundef %md, double noundef 5.000000e-01)
  %p = fmul double %q, 3.000000e+00
  %r = add nsw i32 %m, 1
  %u = fcmp ogt double %p, 1.000000e+01
  br i1 %u, label %ph, label %j
ph:
  call void @cq_phi(double noundef 3.141590e+00)
  br label %j
j:
  %q2 = call double @cq_theta_f64(double noundef %q, double noundef 0x3FE6666666666666)
  %z = call double @cq_measure_f64(double noundef %q2)
  %zi = fptosi double %z to i32
  %s = add nsw i32 %zi, %r
  ret i32 %s
}
