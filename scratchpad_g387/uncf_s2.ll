; ModuleID = 'scratchpad_g387/uncf_s1.ll'
source_filename = "scratchpad_g387/unc_fanout.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: noinline nounwind ssp uwtable
define void @slice(double noundef %0) local_unnamed_addr #0 {
  %h = call i32 @cqrt_alloc_f64(double %0)
  call void @cqrt_ry_f64(i32 %h, double 2.500000e-01)
  %h_libm = call i32 @cq_template_frexp_f64(i32 %h)
  %h_libm1 = call i32 @cq_template_frexpexp_f64_to_i32(i32 %h)
  %h_cast = call i32 @cq_template_fptosi_f64_to_i32(i32 %h_libm)
  call void @cqrt_rz_i32(i32 %h_cast, double 5.000000e-01)
  call void @cqrt_rz_i32(i32 %h_libm1, double 6.000000e-01)
  call void @cqrt_rz_i32(i32 %h_libm1, double -6.000000e-01)
  call void @cqrt_rz_i32(i32 %h_cast, double -5.000000e-01)
  call void @cq_template_fptosi_f64_to_i32_unc(i32 %h_cast, i32 %h_libm)
  call void @cqrt_free(i32 %h_cast)
  call void @cq_template_frexpexp_f64_to_i32_unc(i32 %h_libm1, i32 %h)
  call void @cqrt_free(i32 %h_libm1)
  call void @cq_template_frexp_f64_unc(i32 %h_libm, i32 %h)
  call void @cqrt_free(i32 %h_libm)
  call void @cqrt_ry_f64(i32 %h, double -2.500000e-01)
  call void @cqrt_free(i32 %h)
  ret void
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nofree nounwind willreturn memory(argmem: write)
declare double @frexp(double noundef, ptr nocapture noundef) local_unnamed_addr #2

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #3 {
  tail call void @slice(double noundef 0x3FE6666666666666)
  ret i32 0
}

declare double @cq_byref_frexp_f64(double)

declare i32 @cq_byref_frexpexp_f64(double)

declare void @cqrt_ry_f64(i32, double)

declare i32 @cqrt_alloc_f64(double)

declare void @cqrt_rz_i32(i32, double)

declare i32 @cq_template_frexp_f64(i32)

declare i32 @cq_template_frexpexp_f64_to_i32(i32)

declare i32 @cq_template_fptosi_f64_to_i32(i32)

declare void @cq_template_fptosi_f64_to_i32_unc(i32, i32)

declare void @cqrt_free(i32)

declare void @cq_template_frexpexp_f64_to_i32_unc(i32, i32)

declare void @cq_template_frexp_f64_unc(i32, i32)

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { mustprogress nofree nounwind willreturn memory(argmem: write) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
