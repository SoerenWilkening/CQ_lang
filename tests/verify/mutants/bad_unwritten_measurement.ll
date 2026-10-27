; EXPECT: unwritten-measurement
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @f(i32 %0, double %1) {
  %3 = call i32 @cqrt_alloc_i32(i32 %0)
  call void @cqrt_ry_i32(i32 %3, double %1)
  %4 = call i32 @cqrt_measure_i32(i32 %3), !cq.measure !0
  %5 = call i32 @cqrt_measure_i32(i32 %3), !cq.measure !0
  %6 = add i32 %4, %5
  ret i32 %6
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
