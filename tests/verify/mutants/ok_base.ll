; EXPECT: accept
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @f(i32 %0, double %1, i32 %2) {
  %4 = call i32 @cqrt_alloc_i32(i32 %0)
  call void @cqrt_ry_i32(i32 %4, double %1)
  %5 = call i32 @cq_template_add_i32_hl(i32 %4, i32 %2)
  %6 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %5, i32 7)
  call void @cqrt_rz_i1(i32 %6, double 5.000000e-01)
  %7 = call i32 @cq_template_select_i32(i32 %6, i32 %5, i32 %4)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %6, i32 %5, i32 7)
  call void @cqrt_free(i32 %6)
  call void @cq_template_add_i32_hl_unc(i32 %5, i32 %4, i32 %2)
  call void @cqrt_free(i32 %5)
  %8 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %7, i32 %8)
  %9 = call i32 @cqrt_alloc_i32(i32 %2)
  call void @cqrt_free(i32 %9)
  %10 = call i32 @cqrt_measure_i32(i32 %8), !cq.measure !0
  ret i32 %10
}

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)
declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_select_i32(i32, i32, i32)
declare void @cqrt_copy_i32(i32, i32)
declare void @cqrt_rz_i1(i32, double)
!0 = !{}
