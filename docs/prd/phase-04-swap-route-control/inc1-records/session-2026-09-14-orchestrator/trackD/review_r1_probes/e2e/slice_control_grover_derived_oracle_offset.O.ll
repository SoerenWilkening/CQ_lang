; ModuleID = 'e2e/slice_control_grover_derived_oracle_offset.s1.ll'
source_filename = "/Users/sorenwilkening/Desktop/CQ_lang/tests/e2e/slice_control_grover_derived_oracle_offset.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@off = global i32 3, align 4

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 {
  %h = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %1 = load volatile i32, ptr @off, align 4, !tbaa !6
  call void @cqrt_addc_i32(i32 %h, i32 %1)
  %h_op = call i32 @cq_template_ashr_i32_hl(i32 %h, i32 2)
  %h_op2 = call i32 @cq_template_add_i32(i32 %h, i32 %h_op)
  %h_cmp1 = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op2, i32 5)
  call void @cqrt_rz_i1(i32 %h_cmp1, double 0x400921FB54442D18), !cq.branchphase !10
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp1, i32 %h_op2, i32 5)
  call void @cq_template_add_i32_unc(i32 %h_op2, i32 %h, i32 %h_op)
  call void @cqrt_free(i32 %h_op2)
  call void @cq_template_ashr_i32_hl_unc(i32 %h_op, i32 %h, i32 2)
  call void @cqrt_free(i32 %h_op)
  call void @cqrt_free(i32 %h_cmp1)
  %2 = load volatile i32, ptr @off, align 4, !tbaa !6
  %cq_negimm = sub i32 0, %2
  call void @cqrt_addc_i32(i32 %h, i32 %cq_negimm)
  call void @cqrt_ry_i32(i32 %h, double -5.000000e-01)
  %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h, i32 0)
  call void @cqrt_rz_i1(i32 %h_cmp, double 0x400921FB54442D18), !cq.branchphase !10
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h, i32 0)
  call void @cqrt_free(i32 %h_cmp)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %3 = load volatile i32, ptr @off, align 4, !tbaa !6
  call void @cqrt_addc_i32(i32 %h, i32 %3)
  %m = call i32 @cqrt_measure_i32(i32 %h)
  ret i32 %m
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

declare void @cqrt_addc_i32(i32, i32)

declare i32 @cq_template_ashr_i32_hl(i32, i32)

declare i32 @cq_template_add_i32(i32, i32)

declare i32 @cqrt_measure_i32(i32)

declare void @cq_template_add_i32_unc(i32, i32, i32)

declare void @cq_template_ashr_i32_hl_unc(i32, i32, i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !7, i64 0}
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{}
