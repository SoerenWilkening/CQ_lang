; ModuleID = 'e2e/slice_compare_measure.s1.ll'
source_filename = "/Users/sorenwilkening/Desktop/CQ_lang/tests/e2e/slice_compare_measure.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 {
  %h = call i32 @cqrt_alloc_i32(i32 3)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %h1 = call i32 @cqrt_alloc_f32(float 2.000000e+00)
  call void @cqrt_ry_f32(i32 %h1, double 2.500000e-01)
  %h_cmp = call i32 @cq_template_icmp_slt_i32_hl(i32 %h, i32 10)
  %h_cast = call i32 @cq_template_zext_i1_to_i32(i32 %h_cmp)
  call void @cq_template_icmp_slt_i32_hl_unc(i32 %h_cmp, i32 %h, i32 10)
  call void @cqrt_free(i32 %h_cmp)
  %h_cmp2 = call i32 @cq_template_fcmp_une_f32_hl(i32 %h1, float 1.000000e+00)
  %h_cast3 = call i32 @cq_template_zext_i1_to_i32(i32 %h_cmp2)
  call void @cq_template_fcmp_une_f32_hl_unc(i32 %h_cmp2, i32 %h1, float 1.000000e+00)
  call void @cqrt_free(i32 %h_cmp2)
  %m = call i32 @cqrt_measure_i32(i32 %h_cast)
  %m4 = call i32 @cqrt_measure_i32(i32 %h_cast3)
  %1 = add nsw i32 %m4, %m
  ret i32 %1
}

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #0 {
  %h = call i32 @cqrt_alloc_i32(i32 3)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %h1 = call i32 @cqrt_alloc_f32(float 2.000000e+00)
  call void @cqrt_ry_f32(i32 %h1, double 2.500000e-01)
  %h_cmp = call i32 @cq_template_icmp_slt_i32_hl(i32 %h, i32 10)
  %h_cast = call i32 @cq_template_zext_i1_to_i32(i32 %h_cmp)
  call void @cq_template_icmp_slt_i32_hl_unc(i32 %h_cmp, i32 %h, i32 10)
  call void @cqrt_free(i32 %h_cmp)
  %h_cmp2 = call i32 @cq_template_fcmp_une_f32_hl(i32 %h1, float 1.000000e+00)
  %h_cast3 = call i32 @cq_template_zext_i1_to_i32(i32 %h_cmp2)
  call void @cq_template_fcmp_une_f32_hl_unc(i32 %h_cmp2, i32 %h1, float 1.000000e+00)
  call void @cqrt_free(i32 %h_cmp2)
  %m = call i32 @cqrt_measure_i32(i32 %h_cast)
  %m4 = call i32 @cqrt_measure_i32(i32 %h_cast3)
  ret i32 0
}

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_ry_f32(i32, double)

declare i32 @cqrt_alloc_f32(float)

declare i32 @cq_template_icmp_slt_i32_hl(i32, i32)

declare i32 @cq_template_zext_i1_to_i32(i32)

declare i32 @cq_template_fcmp_une_f32_hl(i32, float)

declare i32 @cqrt_measure_i32(i32)

declare void @cq_template_icmp_slt_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cq_template_fcmp_une_f32_hl_unc(i32, i32, float)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
