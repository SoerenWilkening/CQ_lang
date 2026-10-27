; EXPECT: accept
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @f(i32 %0, double %1, i32 %2) {
  %4 = call i32 @cqrt_alloc_i32(i32 %0)
  call void @cqrt_ry_i32(i32 %4, double %1)
  %5 = call i32 @cqrt_measure_i32(i32 %4), !cq.measure !0
  %6 = icmp sgt i32 %5, %2
  br i1 %6, label %7, label %9
7:
  %8 = call i32 @cq_template_add_i32_hl(i32 %4, i32 %2)
  br label %9
9:
  %10 = phi i32 [ %8, %7 ], [ %4, %3 ]
  %11 = select i1 %6, i32 %10, i32 %4
  %12 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %11, i32 %12)
  %13 = call i32 @cqrt_measure_i32(i32 %12), !cq.measure !0
  ret i32 %13
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
