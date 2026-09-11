; ModuleID = 'p31_three_phi.s1.ll'
source_filename = "../probes/p31_three_phi.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %h = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h, i32 1)
  call void @cqrt_x(i32 %h_cmp)
  %h9 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_ry_i32_controlled(i32 %h_cmp, i32 %h9, double 5.000000e-01)
  call void @cqrt_x(i32 %h_cmp)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h, i32 1)
  call void @cqrt_free(i32 %h_cmp)
  %h_cmp3 = call i32 @cq_template_icmp_eq_i32_hl(i32 %h, i32 1)
  %out = call i32 @cqrt_alloc_i32(i32 0)
  %selop = call i32 @cqrt_alloc_i32(i32 5)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp3, i32 %selop, i32 %out)
  call void @cqrt_x(i32 %h_cmp3)
  %selop4 = call i32 @cqrt_alloc_i32(i32 9)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp3, i32 %selop4, i32 %out)
  call void @cqrt_x(i32 %h_cmp3)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp3, i32 %h, i32 1)
  call void @cqrt_free(i32 %h_cmp3)
  %h_cmp5 = call i32 @cq_template_icmp_eq_i32_hl(i32 %h, i32 1)
  %out6 = call i32 @cqrt_alloc_i32(i32 0)
  %selop7 = call i32 @cqrt_alloc_i32(i32 2)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp5, i32 %selop7, i32 %out6)
  call void @cqrt_x(i32 %h_cmp5)
  %selop8 = call i32 @cqrt_alloc_i32(i32 5)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp5, i32 %selop8, i32 %out6)
  call void @cqrt_x(i32 %h_cmp5)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp5, i32 %h, i32 1)
  call void @cqrt_free(i32 %h_cmp5)
  %m = call i32 @cqrt_measure_i32(i32 %h)
  %m10 = call i32 @cqrt_measure_i32(i32 %h9)
  %1 = add nsw i32 %m10, %m
  %m11 = call i32 @cqrt_measure_i32(i32 %out6)
  %2 = add nsw i32 %1, %m11
  %m12 = call i32 @cqrt_measure_i32(i32 %out)
  %3 = add nsw i32 %2, %m12
  ret i32 %3
}

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

declare void @cqrt_x(i32)

declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_copy_i32_controlled(i32, i32, i32)

declare void @cqrt_ry_i32(i32, double)

declare void @cqrt_ry_i32_controlled(i32, i32, double)

declare i32 @cqrt_measure_i32(i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
