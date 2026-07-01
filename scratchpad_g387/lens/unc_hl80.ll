target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
declare x86_fp80 @cq_theta_f80(x86_fp80, double)
declare i32 @cq_phi_si32(i32, double)
declare x86_fp80 @remquol(x86_fp80, x86_fp80, ptr)
declare void @llvm.lifetime.start.p0(i64, ptr)
declare void @llvm.lifetime.end.p0(i64, ptr)
define void @slice(x86_fp80 %xin) {
entry:
  %q = alloca i32, align 4
  %x = call x86_fp80 @cq_theta_f80(x86_fp80 %xin, double 2.500000e-01)
  call void @llvm.lifetime.start.p0(i64 4, ptr %q)
  %r = call x86_fp80 @remquol(x86_fp80 %x, x86_fp80 0xK4000C000000000000000, ptr %q)
  %qv = load i32, ptr %q, align 4
  %k2 = call i32 @cq_phi_si32(i32 %qv, double 6.000000e-01)
  call void @llvm.lifetime.end.p0(i64 4, ptr %q)
  ret void
}
