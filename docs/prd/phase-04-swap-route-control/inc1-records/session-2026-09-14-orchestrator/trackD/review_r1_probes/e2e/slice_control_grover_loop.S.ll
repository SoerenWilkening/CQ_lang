; ModuleID = 'e2e/slice_control_grover_loop.s1.ll'
source_filename = "/Users/sorenwilkening/Desktop/CQ_lang/tests/e2e/slice_control_grover_loop.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 {
  %h = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  br label %2

1:                                                ; preds = %2
  %m = call i32 @cqrt_measure_i32(i32 %h)
  ret i32 %m

2:                                                ; preds = %2, %0
  %3 = phi i32 [ 0, %0 ], [ %4, %2 ]
  %h_cmp1 = call i32 @cq_template_icmp_eq_i32_hl(i32 %h, i32 5)
  call void @cqrt_rz_i1(i32 %h_cmp1, double 0x400921FB54442D18), !cq.branchphase !6
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp1, i32 %h, i32 5)
  call void @cqrt_free(i32 %h_cmp1)
  call void @cqrt_ry_i32(i32 %h, double -5.000000e-01)
  %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h, i32 0)
  call void @cqrt_rz_i1(i32 %h_cmp, double 0x400921FB54442D18), !cq.branchphase !6
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h, i32 0)
  call void @cqrt_free(i32 %h_cmp)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %4 = add nuw nsw i32 %3, 1
  %5 = icmp eq i32 %3, 0
  br i1 %5, label %2, label %1, !llvm.loop !7
}

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #0 {
  %1 = tail call i32 @slice()
  ret i32 0
}

declare void @cqrt_rz_i1(i32, double)

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

declare void @cqrt_x(i32)

declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

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
!6 = !{}
!7 = distinct !{!7, !8, !9}
!8 = !{!"llvm.loop.mustprogress"}
!9 = !{!"llvm.loop.unroll.disable"}
