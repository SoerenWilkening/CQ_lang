; ModuleID = 'l2iU.s1.ll'
source_filename = "l2iU.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: noinline nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 {
  %h = call i32 @cqrt_alloc_i32(i32 %0)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %h3 = call i32 @cqrt_alloc_i32(i32 %0)
  call void @cqrt_ry_i32(i32 %h3, double 3.000000e-01)
  %h_op = call i32 @cq_template_mul_i32_hl(i32 %h, i32 3)
  %h_op4 = call i32 @cq_template_and_i32_hl(i32 %h_op, i32 1)
  %h_cmp2 = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op4, i32 0)
  call void @cqrt_x(i32 %h_cmp2)
  call void @cqrt_rz_i1(i32 %h_cmp2, double 2.000000e-01), !cq.branchphase !6
  call void @cqrt_x(i32 %h_cmp2)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp2, i32 %h_op4, i32 0)
  call void @cqrt_free(i32 %h_cmp2)
  call void @cqrt_ry_i32(i32 %h3, double 1.000000e-01)
  %h_op5 = call i32 @cq_template_add_i32_hl(i32 %h_op, i32 1)
  %m = call i32 @cqrt_measure_i32(i32 %h_op5)
  %h_op6 = call i32 @cq_template_and_i32_hl(i32 %h_op, i32 2)
  %h_cmp1 = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op6, i32 0)
  call void @cqrt_x(i32 %h_cmp1)
  call void @cqrt_rz_i1(i32 %h_cmp1, double 2.000000e-01), !cq.branchphase !6
  call void @cqrt_x(i32 %h_cmp1)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp1, i32 %h_op6, i32 0)
  call void @cqrt_free(i32 %h_cmp1)
  call void @cqrt_ry_i32(i32 %h3, double 1.000000e-01)
  %m8 = call i32 @cqrt_measure_i32(i32 %h_op5)
  %h_op7 = call i32 @cq_template_and_i32_hl(i32 %h_op, i32 4)
  %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op7, i32 0)
  call void @cqrt_x(i32 %h_cmp)
  call void @cqrt_rz_i1(i32 %h_cmp, double 2.000000e-01), !cq.branchphase !6
  call void @cqrt_x(i32 %h_cmp)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h_op7, i32 0)
  call void @cq_template_and_i32_hl_unc(i32 %h_op7, i32 %h_op, i32 4)
  call void @cqrt_free(i32 %h_op7)
  call void @cq_template_and_i32_hl_unc(i32 %h_op6, i32 %h_op, i32 2)
  call void @cqrt_free(i32 %h_op6)
  call void @cq_template_and_i32_hl_unc(i32 %h_op4, i32 %h_op, i32 1)
  call void @cqrt_free(i32 %h_op4)
  call void @cq_template_mul_i32_hl_unc(i32 %h_op, i32 %h, i32 3)
  call void @cqrt_free(i32 %h_op)
  call void @cqrt_free(i32 %h_cmp)
  call void @cqrt_ry_i32(i32 %h3, double 1.000000e-01)
  %m9 = call i32 @cqrt_measure_i32(i32 %h_op5)
  call void @cqrt_ry_i32(i32 %h, double 9.000000e-01)
  %m10 = call i32 @cqrt_measure_i32(i32 %h)
  %m11 = call i32 @cqrt_measure_i32(i32 %h3)
  %2 = add i32 %m8, %m
  %3 = add i32 %2, %m9
  %4 = add i32 %3, %m10
  %5 = add i32 %4, %m11
  ret i32 %5
}

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 2) i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #1 {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8, !tbaa !7
  %5 = tail call i32 @atoi(ptr nocapture noundef %4)
  %6 = tail call i32 @slice(i32 noundef %5)
  %7 = and i32 %6, 1
  ret i32 %7
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #2

declare void @cqrt_rz_i1(i32, double)

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

declare void @cqrt_x(i32)

declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare i32 @cq_template_mul_i32_hl(i32, i32)

declare i32 @cq_template_and_i32_hl(i32, i32)

declare i32 @cq_template_add_i32_hl(i32, i32)

declare i32 @cqrt_measure_i32(i32)

declare void @cq_template_and_i32_hl_unc(i32, i32, i32)

declare void @cq_template_mul_i32_hl_unc(i32, i32, i32)

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{}
!7 = !{!8, !8, i64 0}
!8 = !{!"any pointer", !9, i64 0}
!9 = !{!"omnipotent char", !10, i64 0}
!10 = !{!"Simple C/C++ TBAA"}
