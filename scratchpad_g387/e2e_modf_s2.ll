; ModuleID = 'scratchpad_g387/e2e_modf_s1.ll'
source_filename = "scratchpad_g387/e2e_modf.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %h = call i32 @cqrt_alloc_f64(double 0.000000e+00)
  call void @cqrt_ry_f64(i32 %h, double 5.000000e-01)
  %h_libm = call i32 @cq_template_modf_f64(i32 %h)
  %h_libm1 = call i32 @cq_template_modfint_f64(i32 %h)
  %h_cast = call i32 @cq_template_fptosi_f64_to_i32(i32 %h_libm)
  %m = call i32 @cqrt_measure_i32(i32 %h_cast)
  %h_cast2 = call i32 @cq_template_fptosi_f64_to_i32(i32 %h_libm1)
  %m3 = call i32 @cqrt_measure_i32(i32 %h_cast2)
  %1 = add nsw i32 %m3, %m
  ret i32 %1
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nofree nounwind willreturn memory(argmem: write)
declare double @modf(double noundef, ptr nocapture noundef) local_unnamed_addr #2

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare double @cq_byref_modf_f64(double)

declare double @cq_byref_modfint_f64(double)

declare void @cqrt_ry_f64(i32, double)

declare i32 @cqrt_alloc_f64(double)

declare i32 @cq_template_modf_f64(i32)

declare i32 @cq_template_modfint_f64(i32)

declare i32 @cq_template_fptosi_f64_to_i32(i32)

declare i32 @cqrt_measure_i32(i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { mustprogress nofree nounwind willreturn memory(argmem: write) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
