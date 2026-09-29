; ModuleID = 'clone_partial_drop.fmt3.s1.ll'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@K = internal global i32 7, align 4

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = add nsw i32 %0, 4
  %4 = and i32 %3, 7
  %h = call i32 @cqrt_alloc_i32(i32 %4)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %h_op = call i32 @cq_template_mul_i32_hl(i32 %h, i32 3)
  %5 = tail call i32 @__cq_q_h_010(i32 noundef 0, i32 noundef %h, i32 noundef %3) #5
  %h_op1 = call i32 @cq_template_xor_i32(i32 %h, i32 %h_op)
  %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op1, i32 10)
  call void @cqrt_rz_i1(i32 %h_cmp, double 3.141590e+00), !cq.branchphase !6
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h_op1, i32 10)
  call void @cq_template_xor_i32_unc(i32 %h_op1, i32 %h, i32 %h_op)
  call void @cqrt_free(i32 %h_op1)
  call void @cq_template_mul_i32_hl_unc(i32 %h_op, i32 %h, i32 3)
  call void @cqrt_free(i32 %h_op)
  call void @cqrt_free(i32 %h_cmp)
  call void @cqrt_ry_i32(i32 %h, double 0x3FE6666666666666)
  %m = call i32 @cqrt_measure_i32(i32 %h)
  %m2 = call i32 @cqrt_measure_i32(i32 %5)
  %6 = add nsw i32 %m2, %m
  ret i32 %6
}

; Function Attrs: mustprogress nofree noinline norecurse nounwind ssp willreturn memory(readwrite, argmem: none) uwtable
define i32 @h2(i32 noundef %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #1 {
  %4 = add nsw i32 %2, %1
  ret i32 %4
}

; Function Attrs: mustprogress nofree norecurse nounwind ssp willreturn uwtable
define i32 @h(i32 noundef %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #2 {
  %4 = musttail call i32 @h2(i32 noundef 0, i32 noundef %1, i32 noundef %2)
  ret i32 %4
}

declare void @cqrt_copy_i32(i32, i32)

declare void @cqrt_rz_i1(i32, double)

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

declare void @cqrt_x(i32)

declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

; Function Attrs: mustprogress norecurse nounwind ssp memory(readwrite) uwtable
define internal i32 @__cq_q_h_010(i32 noundef %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #3 {
  %4 = call i32 @__cq_q_h2_010(i32 noundef 0, i32 noundef %1, i32 noundef %2)
  %cqq.out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %4, i32 %cqq.out)
  call void @__cq_q_h2_010_unc(i32 %4, i32 0, i32 %1, i32 %2)
  call void @cqrt_free(i32 %4)
  ret i32 %cqq.out
}

; Function Attrs: mustprogress noinline norecurse nounwind ssp memory(readwrite) uwtable
define internal i32 @__cq_q_h2_010(i32 noundef %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #4 {
  %h_op = call i32 @cq_template_add_i32_hl(i32 %1, i32 %2)
  %cqq.out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %h_op, i32 %cqq.out)
  call void @cq_template_add_i32_hl_unc(i32 %h_op, i32 %1, i32 %2)
  call void @cqrt_free(i32 %h_op)
  ret i32 %cqq.out
}

declare i32 @cq_template_add_i32_hl(i32, i32)

declare i32 @cqrt_alloc_i32(i32)

declare void @cq_template_add_i32_hl_unc(i32, i32, i32)

; Function Attrs: mustprogress noinline norecurse nounwind ssp memory(readwrite) uwtable
define internal void @__cq_q_h2_010_unc(i32 %out, i32 noundef %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #4 {
  %h_op = call i32 @cq_template_add_i32_hl(i32 %1, i32 %2)
  call void @cqrt_copy_i32(i32 %h_op, i32 %out)
  call void @cq_template_add_i32_hl_unc(i32 %h_op, i32 %1, i32 %2)
  call void @cqrt_free(i32 %h_op)
  ret void
}

declare void @cqrt_ry_i32(i32, double)

declare i32 @cq_template_mul_i32_hl(i32, i32)

declare i32 @cq_template_xor_i32(i32, i32)

declare i32 @cqrt_measure_i32(i32)

declare void @cq_template_xor_i32_unc(i32, i32, i32)

declare void @cq_template_mul_i32_hl_unc(i32, i32, i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nofree noinline norecurse nounwind ssp willreturn memory(readwrite, argmem: none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree norecurse nounwind ssp willreturn uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress norecurse nounwind ssp memory(readwrite) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress noinline norecurse nounwind ssp memory(readwrite) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nounwind }

!llvm.ident = !{!0, !0}
!llvm.module.flags = !{!1, !2, !3, !4, !5}

!0 = !{!"Homebrew clang version 19.1.7"}
!1 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}
!6 = !{}
