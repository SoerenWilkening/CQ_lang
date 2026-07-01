; ModuleID = 'scratchpad_g387/lens/unc_hl80.ll'
source_filename = "scratchpad_g387/lens/unc_hl80.ll"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare x86_fp80 @remquol(x86_fp80, x86_fp80, ptr)

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #0

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #0

define void @slice(x86_fp80 %xin) {
entry:
  %h = call i32 @cqrt_alloc_f80(x86_fp80 %xin)
  call void @cqrt_ry_f80(i32 %h, double 2.500000e-01)
  %h_libm = call i32 @cq_template_remquo_f80_hl(i32 %h, x86_fp80 0xK4000C000000000000000)
  %h_libm1 = call i32 @cq_template_remquoquo_f80_to_i32_hl(i32 %h, x86_fp80 0xK4000C000000000000000)
  call void @cqrt_rz_i32(i32 %h_libm1, double 6.000000e-01)
  call void @cqrt_rz_i32(i32 %h_libm1, double -6.000000e-01)
  call void @cq_template_remquoquo_f80_to_i32_hl_unc(i32 %h_libm1, i32 %h, x86_fp80 0xK4000C000000000000000)
  call void @cqrt_free(i32 %h_libm1)
  call void @cq_template_remquo_f80_hl_unc(i32 %h_libm, i32 %h, x86_fp80 0xK4000C000000000000000)
  call void @cqrt_free(i32 %h_libm)
  call void @cqrt_ry_f80(i32 %h, double -2.500000e-01)
  call void @cqrt_free(i32 %h)
  ret void
}

declare void @cqrt_ry_f80(i32, double)

declare i32 @cqrt_alloc_f80(x86_fp80)

declare void @cqrt_rz_i32(i32, double)

declare i32 @cq_template_remquo_f80_hl(i32, x86_fp80)

declare i32 @cq_template_remquoquo_f80_to_i32_hl(i32, x86_fp80)

declare void @cq_template_remquoquo_f80_to_i32_hl_unc(i32, i32, x86_fp80)

declare void @cqrt_free(i32)

declare void @cq_template_remquo_f80_hl_unc(i32, i32, x86_fp80)

attributes #0 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
