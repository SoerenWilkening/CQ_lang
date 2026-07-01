; ModuleID = 'scratchpad_g387/lens/unc_qq.ll'
source_filename = "scratchpad_g387/lens/unc_qq.ll"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare double @remquo(double, double, ptr)

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #0

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #0

define void @slice(double %xin, double %yin) {
entry:
  %h = call i32 @cqrt_alloc_f64(double %xin)
  call void @cqrt_ry_f64(i32 %h, double 2.500000e-01)
  %h1 = call i32 @cqrt_alloc_f64(double %yin)
  call void @cqrt_ry_f64(i32 %h1, double 3.000000e-01)
  %h_libm = call i32 @cq_template_remquo_f64(i32 %h, i32 %h1)
  %h_libm2 = call i32 @cq_template_remquoquo_f64_to_i32(i32 %h, i32 %h1)
  %h_cast = call i32 @cq_template_fptosi_f64_to_i32(i32 %h_libm)
  call void @cqrt_rz_i32(i32 %h_cast, double 5.000000e-01)
  call void @cqrt_rz_i32(i32 %h_libm2, double 6.000000e-01)
  call void @cqrt_rz_i32(i32 %h_libm2, double -6.000000e-01)
  call void @cqrt_rz_i32(i32 %h_cast, double -5.000000e-01)
  call void @cq_template_fptosi_f64_to_i32_unc(i32 %h_cast, i32 %h_libm)
  call void @cqrt_free(i32 %h_cast)
  call void @cq_template_remquoquo_f64_to_i32_unc(i32 %h_libm2, i32 %h, i32 %h1)
  call void @cqrt_free(i32 %h_libm2)
  call void @cq_template_remquo_f64_unc(i32 %h_libm, i32 %h, i32 %h1)
  call void @cqrt_free(i32 %h_libm)
  call void @cqrt_ry_f64(i32 %h1, double -3.000000e-01)
  call void @cqrt_free(i32 %h1)
  call void @cqrt_ry_f64(i32 %h, double -2.500000e-01)
  call void @cqrt_free(i32 %h)
  ret void
}

declare void @cqrt_ry_f64(i32, double)

declare i32 @cqrt_alloc_f64(double)

declare void @cqrt_rz_i32(i32, double)

declare i32 @cq_template_remquo_f64(i32, i32)

declare i32 @cq_template_remquoquo_f64_to_i32(i32, i32)

declare i32 @cq_template_fptosi_f64_to_i32(i32)

declare void @cq_template_fptosi_f64_to_i32_unc(i32, i32)

declare void @cqrt_free(i32)

declare void @cq_template_remquoquo_f64_to_i32_unc(i32, i32, i32)

declare void @cq_template_remquo_f64_unc(i32, i32, i32)

attributes #0 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
