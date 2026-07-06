; ModuleID = '/Users/sorenwilkening/Desktop/CQ_lang/demo/foo_superposition/foo_noinline.frontend.ll'
source_filename = "/Users/sorenwilkening/Desktop/CQ_lang/demo/foo_superposition/foo_noinline.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483648, 5) i32 @foo(i32 noundef %0) local_unnamed_addr #0 {
  %2 = icmp slt i32 %0, 5
  %3 = select i1 %2, i32 %0, i32 0
  ret i32 %3
}

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #1 {
  %h = call i32 @cqrt_alloc_i32(i32 %0)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %3 = tail call i32 @__cq_q_foo_1(i32 noundef %h)
  %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %3, i32 0)
  %rail = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_x(i32 %h_cmp)
  call void @cqrt_cswap(i32 %h_cmp, i32 %3, i32 %rail)
  call void @cqrt_x(i32 %h_cmp)
  call void @cqrt_rz_i32(i32 %rail, double 3.140000e+00)
  call void @cqrt_x(i32 %h_cmp)
  call void @cqrt_cswap(i32 %h_cmp, i32 %3, i32 %rail)
  call void @cqrt_x(i32 %h_cmp)
  call void @cqrt_free(i32 %rail)
  %h_cmp1 = call i32 @cq_template_icmp_eq_i32_hl_inv(i32 %3, i32 0)
  call void @cqrt_free(i32 %h_cmp)
  %m = call i32 @cqrt_measure_i32(i32 %3)
  ret i32 %m
}

declare void @cqrt_copy_i32(i32, i32)

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_rz_i32(i32, double)

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

declare void @cqrt_cswap(i32, i32, i32)

declare void @cqrt_x(i32)

declare void @cqrt_free(i32)

declare i32 @cq_template_icmp_eq_i32_hl_inv(i32, i32)

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal i32 @__cq_q_foo_1(i32 noundef %0) local_unnamed_addr #2 {
  %h_cmp = call i32 @cq_template_icmp_slt_i32_hl(i32 %0, i32 5)
  %cqq.sel = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %0, i32 %cqq.sel)
  %cqq.out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %cqq.sel, i32 %cqq.out)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %0, i32 %cqq.sel)
  call void @cq_template_icmp_slt_i32_hl_unc(i32 %h_cmp, i32 %0, i32 5)
  call void @cqrt_free(i32 %h_cmp)
  call void @cqrt_free(i32 %cqq.sel)
  ret i32 %cqq.out
}

declare void @cqrt_copy_i32_controlled(i32, i32, i32)

declare i32 @cq_template_icmp_slt_i32_hl(i32, i32)

declare void @cq_template_icmp_slt_i32_hl_unc(i32, i32, i32)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_measure_i32(i32)

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
