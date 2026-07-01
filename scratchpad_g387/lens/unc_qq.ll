target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
declare double @cq_theta_f64(double, double)
declare i32 @cq_phi_si32(i32, double)
declare double @remquo(double, double, ptr)
declare void @llvm.lifetime.start.p0(i64, ptr)
declare void @llvm.lifetime.end.p0(i64, ptr)
define void @slice(double %xin, double %yin) {
entry:
  %q = alloca i32, align 4
  %x = call double @cq_theta_f64(double %xin, double 2.500000e-01)
  %y = call double @cq_theta_f64(double %yin, double 3.000000e-01)
  call void @llvm.lifetime.start.p0(i64 4, ptr %q)
  %r = call double @remquo(double %x, double %y, ptr %q)
  %ri = fptosi double %r to i32
  %k1 = call i32 @cq_phi_si32(i32 %ri, double 5.000000e-01)
  %qv = load i32, ptr %q, align 4
  %k2 = call i32 @cq_phi_si32(i32 %qv, double 6.000000e-01)
  call void @llvm.lifetime.end.p0(i64 4, ptr %q)
  ret void
}
