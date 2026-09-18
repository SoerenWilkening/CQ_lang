; ModuleID = '/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d9542657-7eae-4089-ae6b-77dc3ed77cc3/scratchpad/rev/creach/notc_4.s1.ll'
source_filename = "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d9542657-7eae-4089-ae6b-77dc3ed77cc3/scratchpad/rev/creach/notc_4.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #0 {
  %h = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %h_cmp14 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 1)
  %h_cmp = call i32 @cq_template_icmp_sle_i32_hl(i32 %h, i32 1)
  %out = call i32 @cqrt_alloc_i32(i32 0)
  %selop = call i32 @cqrt_alloc_i32(i32 2)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %selop, i32 %out)
  call void @cqrt_x(i32 %h_cmp)
  %selop1 = call i32 @cqrt_alloc_i32(i32 7)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %selop1, i32 %out)
  call void @cqrt_x(i32 %h_cmp)
  call void @cq_template_icmp_sle_i32_hl_unc(i32 %h_cmp, i32 %h, i32 1)
  call void @cqrt_free(i32 %h_cmp)
  %h_cmp2 = call i32 @cq_template_icmp_sle_i32_hl(i32 %h, i32 1)
  %out3 = call i32 @cqrt_alloc_i32(i32 0)
  %selop4 = call i32 @cqrt_alloc_i32(i32 2)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp2, i32 %selop4, i32 %out3)
  call void @cqrt_x(i32 %h_cmp2)
  %selop5 = call i32 @cqrt_alloc_i32(i32 8)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp2, i32 %selop5, i32 %out3)
  call void @cqrt_x(i32 %h_cmp2)
  call void @cq_template_icmp_sle_i32_hl_unc(i32 %h_cmp2, i32 %h, i32 1)
  call void @cqrt_free(i32 %h_cmp2)
  %h_cmp6 = call i32 @cq_template_icmp_sle_i32_hl(i32 %h, i32 1)
  %out7 = call i32 @cqrt_alloc_i32(i32 0)
  %selop8 = call i32 @cqrt_alloc_i32(i32 2)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp6, i32 %selop8, i32 %out7)
  call void @cqrt_x(i32 %h_cmp6)
  %selop9 = call i32 @cqrt_alloc_i32(i32 6)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp6, i32 %selop9, i32 %out7)
  call void @cqrt_x(i32 %h_cmp6)
  call void @cq_template_icmp_sle_i32_hl_unc(i32 %h_cmp6, i32 %h, i32 1)
  call void @cqrt_free(i32 %h_cmp6)
  %h_cmp10 = call i32 @cq_template_icmp_sle_i32_hl(i32 %h, i32 1)
  %out11 = call i32 @cqrt_alloc_i32(i32 0)
  %selop12 = call i32 @cqrt_alloc_i32(i32 2)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp10, i32 %selop12, i32 %out11)
  call void @cqrt_x(i32 %h_cmp10)
  %selop13 = call i32 @cqrt_alloc_i32(i32 5)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp10, i32 %selop13, i32 %out11)
  call void @cqrt_x(i32 %h_cmp10)
  call void @cq_template_icmp_sle_i32_hl_unc(i32 %h_cmp10, i32 %h, i32 1)
  call void @cqrt_free(i32 %h_cmp10)
  br label %1

1:                                                ; preds = %0
  %h_op = call i32 @cq_template_xor_i1_hl(i32 %h_cmp14, i1 true)
  %m = call i32 @cqrt_measure_i32(i32 %out11)
  %m15 = call i32 @cqrt_measure_i32(i32 %out7)
  %m16 = call i32 @cqrt_measure_i32(i32 %out)
  %m17 = call i32 @cqrt_measure_i32(i32 %out3)
  %m18 = call i1 @cqrt_measure_i1(i32 %h_cmp14)
  %m19 = call i1 @cqrt_measure_i1(i32 %h_op)
  %m20 = call i32 @cqrt_measure_i32(i32 %h)
  ret i32 0
}

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_copy_i32_controlled(i32, i32, i32)

declare i32 @cq_template_icmp_sle_i32_hl(i32, i32)

declare void @cqrt_x(i32)

declare void @cq_template_icmp_sle_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)

declare i32 @cq_template_xor_i1_hl(i32, i1)

declare i32 @cqrt_measure_i32(i32)

declare i1 @cqrt_measure_i1(i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
